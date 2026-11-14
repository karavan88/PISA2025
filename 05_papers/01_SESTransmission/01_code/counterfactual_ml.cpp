// Profiled Gaussian random-intercept ML / weighted pseudo-ML.
// Same sufficient statistics and objective as the archived R engine.
// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <cmath>
#ifdef __APPLE__
extern "C" void cblas_dsyrk(const int,const int,const int,const int,const int,const double,const double*,const int,const double,double*,const int);
#endif
using namespace Rcpp;
using namespace arma;

arma::mat weighted_cross(const arma::mat& X, const arma::vec& w) {
 arma::mat WX=X.each_col()%sqrt(w), ans(X.n_cols,X.n_cols,arma::fill::zeros);
#ifdef __APPLE__
 // Standard CBLAS enum values: column-major=102, upper=121, transpose=112.
 cblas_dsyrk(102,121,112,(int)X.n_cols,(int)X.n_rows,
             1.0,WX.memptr(),(int)X.n_rows,0.0,ans.memptr(),(int)X.n_cols);
#else
 ans=WX.t()*WX;
#endif
 return arma::symmatu(ans);
}

// Bounded Brent minimization on log variance ratio; zero is compared separately.
template<class F> double minimize_profile(F f) {
 double a=-18,b=12,x=a+.3819660112501051*(b-a),w=x,v=x;
 double fx=f(x),fw=fx,fv=fx,e=0,d=0;
 for(int it=0;it<150;++it){
  double mid=.5*(a+b),tol=1.4901161193847656e-8*std::abs(x)+1e-8/3, t2=2*tol;
  if(std::abs(x-mid)<=t2-.5*(b-a))break;
  bool para=false;
  if(std::abs(e)>tol){
   double r=(x-w)*(fx-fv),q=(x-v)*(fx-fw),p=(x-v)*q-(x-w)*r;
   q=2*(q-r);if(q>0)p=-p;q=std::abs(q);double old=e;e=d;
   if(q>0 && std::abs(p)<std::abs(.5*q*old) && p>q*(a-x) && p<q*(b-x)){
    d=p/q;double u=x+d;if(u-a<t2||b-u<t2)d=(mid>=x?tol:-tol);para=true;
   }
  }
  if(!para){e=(x>=mid?a-x:b-x);d=.3819660112501051*e;}
  double u=x+(std::abs(d)>=tol?d:(d>=0?tol:-tol)),fu=f(u);
  if(fu<=fx){if(u>=x)a=x;else b=x;v=w;fv=fw;w=x;fw=fx;x=u;fx=fu;}
  else {if(u<x)a=u;else b=u;if(fu<=fw||w==x){v=w;fv=fw;w=u;fw=fu;}else if(fu<=fv||v==x||v==w){v=u;fv=fu;}}
 }
 return std::exp(x);
}

// [[Rcpp::export]]
arma::mat fast_weighted_ml(const List& s, const arma::vec& mult) {
 mat xx=as<mat>(s["xx"]),xy=as<mat>(s["xy"]),yy=as<mat>(s["yy"]),B=as<mat>(s["B"]),Y=as<mat>(s["Y"]);
 vec n=as<vec>(s["n"]),w=as<vec>(s["w2"])%mult;int p=as<int>(s["p"]),q=as<int>(s["q"]);
 mat A=reshape(xx.t()*w,p,p),XY=reshape(xy.t()*w,p,q),bw=solve(A,XY,solve_opts::likely_sympd);
 vec ssw=yy.t()*w-sum(XY%bw,0).t();double nn=dot(n,w);mat ans(p+B.n_cols,q);
 for(int k=0;k<q;k++){
  auto at=[&](double lambda, vec* out)->double {
   vec wb=w%n/(1+n*lambda);mat BB=weighted_cross(B,wb);vec by=B.t()*(wb%Y.col(k));
   vec cf=solve(BB,by,solve_opts::likely_sympd);vec r=Y.col(k)-B*cf;
   double ss=ssw(k)+dot(wb,square(r));if(out)*out=cf;
   return nn*std::log(ss/nn)+dot(w,log(1+n*lambda));
  };
  double lambda=minimize_profile([&](double x){return at(std::exp(x),nullptr);});
  if(at(0,nullptr)<at(lambda,nullptr))lambda=0;
  vec cf;at(lambda,&cf);ans.col(k)=join_cols(bw.col(k),cf);
 }
 return ans;
}

// [[Rcpp::export]]
arma::mat fast_unweighted_ml(const List& s,const arma::vec& mult) {
 mat xx=as<mat>(s["xx"]),xy=as<mat>(s["xy"]),yy=as<mat>(s["yy"]),X=as<mat>(s["X"]),Y=as<mat>(s["Y"]);
 vec n=as<vec>(s["n"]);int p=as<int>(s["p"]),q=as<int>(s["q"]);
 mat A=reshape(xx.t()*mult,p,p),XY=reshape(xy.t()*mult,p,q);vec YY=yy.t()*mult;
 double nn=dot(n,mult);mat ans(p,q);
 for(int k=0;k<q;k++){
  auto at=[&](double lambda,vec* out)->double {
   vec w=mult%n/(1+n*lambda);mat xx=A+weighted_cross(X,w);vec xy=XY.col(k)+X.t()*(w%Y.col(k));
   vec cf=solve(xx,xy,solve_opts::likely_sympd);double ss=YY(k)+dot(w,square(Y.col(k)))-dot(cf,xy);
   if(out)*out=cf;return nn*std::log(ss/nn)+dot(mult,log(1+n*lambda));
  };
  double lambda=minimize_profile([&](double x){return at(std::exp(x),nullptr);});
  if(at(0,nullptr)<at(lambda,nullptr))lambda=0;
  vec cf;at(lambda,&cf);ans.col(k)=cf;
 }
 return ans;
}
