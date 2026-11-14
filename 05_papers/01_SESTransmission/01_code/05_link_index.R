# Join the existing full-family gradient adjustment; never invent b-coefficient q-values.
link_index <- E[grepl('^[ab][WB]_',term)]
link_q <- H[scope=='All available blocks' & grepl('^a[WB]_',term),
            .(CNT,exposure,term,gradient_q=summary_q,gradient_q_family=family)]
stopifnot(!anyDuplicated(link_q[,.(CNT,exposure,term)]))
link_index <- merge(link_index,link_q,by=c('CNT','exposure','term'),all.x=TRUE)
stopifnot(nrow(link_index)==3512, all(is.finite(link_index[grepl('^a',term),gradient_q])),
          all(is.na(link_index[grepl('^b',term),gradient_q])))
fwrite(link_index[order(exposure,economy,term)],file.path(OUT,'tables/country_link_coefficients.csv'))
