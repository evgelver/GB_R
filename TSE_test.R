r.version <-  paste0("R-", version$major, ".", version$minor)
lib <- paste0("C:/Program Files/R/", r.version, "/library")
destdir <- "C:/distr/R-pack/"
repos <- "https://cran.r-project.org/package=TraMineRextras"

# дать права на запись в lib и destdir

#################################################################################
# TraMineR
#################################################################################
install.packages(
  pkg = "TraMineRextras", 
  lib = lib, 
  destdir = destdir,
)

# загрузка библиотеки
library(TraMineR)
library(TraMineRextras)

# данные
data(actcal.tse)

# Объект последовательностей событий
event_seq <- seqecreate(
  id=actcal.tse$id,
  time=actcal.tse$time, 
  event=actcal.tse$event
)
event_seq[[4]]

# поиск частых подпоследовательностей
fsubseq <- seqefsub(event_seq, min.support=20, pmin.support=1e-5)
print(fsubseq)

# датафрейм: в строках ИД последовательностей, 
# в столбцах - признаки наличия частых подпоследовательностей
data <- data.frame(seq_id = unique(actcal.tse$id),seqeapplysub(fsubseq, method="presence")
)

# Расстояние между подпоследовательностями (расстояние Левенштейна)
seq_data <- seqdef(data)
OM <- seqdist(seq_data, method = 'OM', sm=seqsubm(seq_data, method = "CONSTANT"))

# Время окончания последовательности состояний
end_time <- function(tse){
  return(max(tse$time)+1)
}

# множество событий
events <- c(levels(actcal.tse$event))
events

## Удаление предыдущих событий
stm <- seqe2stm(events, dropList=list(PartTime=events[-1],
      NoActivity=events[-2], Start=events[-3], FullTime=events[-4], 
      Stop=events[-5], LowPartTime=events[-6], Increase=events[-7], Decrease=events[-8]))

# Из формата TSE в формат STS
actcal.sts <- TSE_to_STS(actcal.tse, id=1, timestamp=2, event=3,
                        stm=stm, tmin=1, tmax=end_time(actcal.tse), firstState="None")
actcal.seq <- seqdef(actcal.sts, informat = 'STS')

# 2 метрики:
# 1.the Longest Common Prefix LCP
# 2.the Optimal Mathing distances (OM)
LCP_dist <- seqdist(actcal.seq, method = "LCP", norm = 'auto')
OM_dist <- seqdist(actcal.seq, method = "OM", norm = 'auto', 
                  sm=seqsubm(actcal.seq, method = "CONSTANT"))


# суммирование матриц (матрица подпоследовательностей с коэффицентом)
# w - коэффицент
# OM - матрица расстояний (STS)
# OM_subseq - матрица расстояний (Subseq)
result_matrix <- function(w,OM,OM_subseq) {
  return(OM+w*OM_subseq)
} 

# запись файла
write.table(result_matrix(3,OM_dist,OM), file="Result_df_toy_coef.csv")
