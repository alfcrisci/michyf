library(readxl)
library(fitdistrplus)
library(doBy)
library(XLConnect)
library(ggplot2)

setwd("/home/alf/Scrivania/lav_michyf/lav_PDI/adults")

micotoxins=excel_sheets("biomarcatori_PDI.xlsx")

pdi_func_DON=function(x,escr=70,vol_urine=2,weight=70) {return(x*(vol_urine/weight)*(100/escr))}
pdi_func=function(x,escr=70,vol_urine=2,weight=70) {return(x*(vol_urine/weight)*(100/escr))}



sumfit=function(x) {return(data.frame(par=x$estimate[1],errpar=x$estimate[2],aic=x$aic,names=x$distname))}

####################################################################################
# from Piero Toscano
# C = i valori di concentrazione che trovi nel file xls
# V = quantità urine per adulti 2Litri (EFSA, NDA) ma abbiamo ref con range [1, 2.4] Litri
# W = adulti 70 kg, bambini fino a 9 anni = 30kg. 
# 
# Nel file xls per tutti i dati di Brera 2015 abbiamo pure il peso
# 

####################################################################################
# DON analisys
# E (DON) = 72.3% Turner, 2010; 68% Warth 2013; 70% EFSA, 2017

EDON=70

DON_data=as.data.frame(read_excel("biomarcatori_PDI.xlsx",1))
names(DON_data)[5:6]=c("weight","biomark")
table(DON_data$Sex,DON_data$Country)


Full_mat_DON=DON_data[which(DON_data$Country %in% c("IT","NO","UK")==T),]

DON_data_nation=summaryBy(biomark~Sex+Country,data=Full_mat_DON, FUN=c(mean,sd), na.rm=TRUE)

M_data_DON=Full_mat_DON[Full_mat_DON$Sex=="Male",]
F_data_DON=Full_mat_DON[Full_mat_DON$Sex=="Female",]

M_data_DON_nation=split(M_data_DON,M_data_DON$Country) # IT 1 NO 2 UK 3
F_data_DON_nation=split(F_data_DON,F_data_DON$Country)

##############################################################################
# collect DON data

data_DON_ls=list()
data_DON_ls$data_DON_tot=as.numeric(na.omit(Full_mat_DON$biomark))
data_DON_ls$data_M_DON_tot=as.numeric(na.omit(M_data_DON$biomark))
data_DON_ls$data_F_DON_tot=as.numeric(na.omit(F_data_DON$biomark))
data_DON_ls$data_M_DON_IT=as.numeric(na.omit(M_data_DON_nation[[1]]$biomark))
data_DON_ls$data_F_DON_IT=as.numeric(na.omit(F_data_DON_nation[[1]]$biomark))
data_DON_ls$data_M_DON_NO=as.numeric(na.omit(M_data_DON_nation[[2]]$biomark))
data_DON_ls$data_F_DON_NO=as.numeric(na.omit(F_data_DON_nation[[2]]$biomark))
data_DON_ls$data_M_DON_UK=as.numeric(na.omit(M_data_DON_nation[[3]]$biomark))
data_DON_ls$data_F_DON_UK=as.numeric(na.omit(F_data_DON_nation[[3]]$biomark))
saveRDS(data_DON_ls,"data_DON_ls.rds")

set.seed(2)

##############################################################################################################################
names_DON=c("DON_tot",
          "M_DON_tot",
          "F_DON_tot",
          "M_DON_UK",
          "M_DON_IT",
          "M_DON_NO",
          "F_DON_UK",
          "F_DON_IT",
          "F_DON_NO")


res_DON=list(
DON_tot=fitdist(data_DON_ls$data_DON_tot,"norm"),
M_DON_tot=fitdist(data_DON_ls$data_M_DON_tot,"norm"),
F_DON_tot=fitdist(data_DON_ls$data_F_DON_tot,"norm"),
M_DON_UK=fitdist(data_DON_ls$data_M_DON_UK,"norm"),
M_DON_IT=fitdist(data_DON_ls$data_M_DON_IT,"norm"),
M_DON_NO=fitdist(data_DON_ls$data_M_DON_NO,"norm"),
F_DON_UK=fitdist(data_DON_ls$data_F_DON_UK,"norm"),
F_DON_IT=fitdist(data_DON_ls$data_F_DON_IT,"norm"),
F_DON_NO=fitdist(data_DON_ls$data_F_DON_NO,"norm"),
DON_tote=fitdist(data_DON_ls$data_DON_tot,"exp"),
M_DON_tote=fitdist(data_DON_ls$data_M_DON_tot,"exp"),
F_DON_tote=fitdist(data_DON_ls$data_F_DON_tot,"exp"),
M_DON_UKe=fitdist(data_DON_ls$data_M_DON_UK,"exp"),
M_DON_ITe=fitdist(data_DON_ls$data_M_DON_IT,"exp"),
M_DON_NOe=fitdist(data_DON_ls$data_M_DON_NO,"exp"),
F_DON_UKe=fitdist(data_DON_ls$data_F_DON_UK,"exp"),
F_DON_ITe=fitdist(data_DON_ls$data_F_DON_IT,"exp"),
F_DON_NOe=fitdist(data_DON_ls$data_F_DON_NO,"exp")
)

df_res_DON=data.frame(names=names(res_DON),do.call("rbind",lapply(res_DON,FUN=sumfit)))
row.names(df_res_DON)=NULL

for (i in 1:9) {

png(paste0(names_DON[i],".png"))
f=i+9
denscomp(res_DON[c(i,f)],legendtext = c("Normal", "Exponential"),
         main = paste("Fitting",names_DON[i],"biomarker data"), xlab = "microg/L")

dev.off()

}



exp_par_DON=df_res_DON$par[10:18] 
res_pdi_DON=list()
for ( i in 1:length(exp_par_DON)) {
                                  temp_PDI=sapply(rexp(10000,exp_par_DON[i]),FUN=function(x){ pdi_func(x)})
                                  res_pdi_DON[[i]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))
}

df_pdi_DON=data.frame(name=names_DON,do.call("rbind",res_pdi_DON))
names(df_pdi_DON) [2:4]=c("mean","conf.int.inf","conf.int.sup")


  
####################################################################################
# AFM1 analisys
# E (AFM1) = 1.23-2.18% MALE (Zhu, 1987)
# E (AFM1) = 1.30-1.78% FEMALE (Zhu, 1987)

EAFM1M=1.705
EAFM1F=1.54


AFM1_data=as.data.frame(read_excel("biomarcatori_PDI.xlsx",3))
names(AFM1_data)[5]=c("biomark")
Full_mat_AFM1=AFM1_data

pFull_mat_AFM1=Full_mat_AFM1[which(!is.na(Full_mat_AFM1$Sex)),]

M_data_AFM1=Full_mat_AFM1[pFull_mat_AFM1$Sex=="Male",]
F_data_AFM1=Full_mat_AFM1[pFull_mat_AFM1$Sex=="Female",]

data_AFM1_ls=list()
data_AFM1_ls$data_AFM1_tot=as.numeric(na.omit(pFull_mat_AFM1$biomark))
data_AFM1_ls$data_M_AFM1_tot=as.numeric(na.omit(M_data_AFM1$biomark))
data_AFM1_ls$data_F_AFM1_tot=as.numeric(na.omit(F_data_AFM1$biomark))
saveRDS(data_AFM1_ls,"data_AFM1_ls.rds")

res_AFM1=list(
AFM1_tot=fitdist(data_AFM1_ls$data_AFM1_tot,"norm"),
M_AFM1_tot=fitdist(data_AFM1_ls$data_M_AFM1_tot,"norm"),
F_AFM1_tot=fitdist(data_AFM1_ls$data_F_AFM1_tot,"norm"),
AFM1_tot_e=fitdist(data_AFM1_ls$data_AFM1_tot,"exp"),
M_AFM1_tot_e=fitdist(data_AFM1_ls$data_M_AFM1_tot,"exp"),
F_AFM1_tot_e=fitdist(data_AFM1_ls$data_F_AFM1_tot,"exp")
)

df_res_AFM1=data.frame(names=names(res_AFM1),do.call("rbind",lapply(res_AFM1,FUN=sumfit)))
row.names(df_res_AFM1)=NULL

names_AFM1=c("AFM1_tot",
            "M_AFM1_tot",
            "F_AFM1_tot")

png(paste0(names_AFM1[1],".png"))
denscomp(res_AFM1[c(1,4)],legendtext = c("Normal", "Exponential"),
         main = "Fitting AFM1 biomarker full data", xlab = "microg/L")
dev.off()
png(paste0(names_AFM1[2],".png"))

denscomp(res_AFM1[c(2,5)],legendtext = c("Normal", "Exponential"),
         main = "Fitting AFM1 biomarkerMale data", xlab = "microg/L")
dev.off()

png(paste0(names_AFM1[3],".png"))
denscomp(res_AFM1[c(3,6)],legendtext = c("Normal", "Exponential"),
         main = "Fitting AFM1 biomarker Female data", xlab = "microg/L")
dev.off()



res_pdi_AFM1=list()

temp_PDI=sapply(rexp(10000,df_res_AFM1$par[4]),FUN=function(x){ pdi_func(x,escr = mean(EAFM1M,EAFM1F))})
res_pdi_AFM1[[1]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))
temp_PDI=sapply(rexp(10000,df_res_AFM1$par[5]),FUN=function(x){ pdi_func(x,escr = mean(EAFM1M))})
res_pdi_AFM1[[2]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))
temp_PDI=sapply(rexp(10000,df_res_AFM1$par[6]),FUN=function(x){ pdi_func(x,escr = mean(EAFM1F))})
res_pdi_AFM1[[3]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))

df_pdi_AFM1=data.frame(name=names_AFM1,do.call("rbind",res_pdi_AFM1))
names(df_pdi_AFM1) [2:4]=c("mean","conf.int.inf","conf.int.sup")


####################################################################################
# FB analisys
# E (FBs) = 0.3% (van der Westhuizen et al., 2011)
# 

EFB=0.3
FB_data=as.data.frame(read_excel("biomarcatori_PDI.xlsx",2))
denscomp(list(F_DON_IT,F_DON_ITg))
names(FB_data)[5]=c("biomark")
Full_mat_FB=FB_data
data_FB_ls=list()
data_FB_ls$data_FB_tot=as.numeric(na.omit(Full_mat_FB$biomark))
saveRDS(data_FB_ls,"data_FB_ls.rds")

res_FB=list(
  FB_tot=fitdist(data_FB_ls$data_FB_tot,"norm"),
  FB_tot_e=fitdist(data_FB_ls$data_FB_tot,"exp")
)

df_res_FB=data.frame(names=names(res_FB),do.call("rbind",lapply(res_FB,FUN=sumfit)))
row.names(df_res_FB)=NULL


png(paste0("FB_tot.png"))
denscomp(res_FB[c(1,2)],legendtext = c("Normal", "Exponential"),
         main = "Fitting FB biomarker full data", xlab = "microg/L")
dev.off()

res_pdi_FB=list()

temp_PDI=sapply(rexp(10000,df_res_FB$par[2]),FUN=function(x){ pdi_func(x,escr = mean(EFB))})
res_pdi_FB[[1]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))

df_pdi_FB=data.frame(name="FB_tot",do.call("rbind",res_pdi_FB))
names(df_pdi_FB) [2:4]=c("mean","conf.int.inf","conf.int.sup")

######################################################################################################

EZEN=9.4 # (range 7-13.2) Excretion rate (Warth, 2013)

ZEN_data=as.data.frame(read_excel("biomarcatori_PDI_2.xlsx",4))
names(ZEN_data)[5]=c("biomark")
Full_mat_ZEN=ZEN_data
data_ZEN_ls=list()
data_ZEN_ls$data_ZEN_tot=as.numeric(na.omit(Full_mat_ZEN$biomark))
saveRDS(data_ZEN_ls,"data_ZEN_ls.rds")



res_ZEN=list(
  ZEN_tot=fitdist(data_ZEN_ls$data_ZEN_tot,"norm"),
  ZEN_tot_e=fitdist(data_ZEN_ls$data_ZEN_tot,"exp")
)


df_res_ZEN=data.frame(names="ZEN_tot",do.call("rbind",lapply(res_ZEN,FUN=sumfit)))
row.names(df_res_ZEN)=NULL


png(paste0("ZEN_tot.png"))
denscomp(res_ZEN[c(1,2)],legendtext = c("Normal", "Exponential"),
         main = "Fitting ZEN biomarker full data", xlab = "microg/L")

dev.off()

res_pdi_ZEN=list()

temp_PDI=sapply(rexp(10000,df_res_ZEN$par[2]),FUN=function(x){ pdi_func(x,escr = mean(EZEN))})
res_pdi_ZEN[[1]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))

df_pdi_ZEN=data.frame(name="ZEN_tot",do.call("rbind",res_pdi_ZEN))
names(df_pdi_ZEN) [2:4]=c("mean","conf.int.inf","conf.int.sup")

####################################################################################
# OTA analisys
# E (OTA) = 50% (Schlatter et al., 1996)

EOTA=50

OTA_data=as.data.frame(read_excel("biomarcatori_PDI.xlsx",4))
names(OTA_data)[5]=c("biomark")
Full_mat_OTA=OTA_data
data_OTA_ls=list()
data_OTA_ls$data_OTA_tot=as.numeric(na.omit(Full_mat_OTA$biomark))
saveRDS(data_OTA_ls,"data_OTA_ls.rds")



res_OTA=list(
  OTA_tot=fitdist(data_OTA_ls$data_OTA_tot,"norm"),
  OTA_tot_e=fitdist(data_OTA_ls$data_OTA_tot,"exp")
)


df_res_OTA=data.frame(names="OTA_tot",do.call("rbind",lapply(res_OTA,FUN=sumfit)))
row.names(df_res_OTA)=NULL


png(paste0("OTA_tot.png"))
denscomp(res_OTA[c(1,2)],legendtext = c("Normal", "Exponential"),
         main = "Fitting OTA biomarker full data", xlab = "microg/L")

dev.off()

res_pdi_OTA=list()

temp_PDI=sapply(rexp(10000,df_res_OTA$par[2]),FUN=function(x){ pdi_func(x,escr = mean(EOTA))})
res_pdi_OTA[[1]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))

df_pdi_OTA=data.frame(name="OTA_tot",do.call("rbind",res_pdi_OTA))
names(df_pdi_OTA) [2:4]=c("mean","conf.int.inf","conf.int.sup")


##############################################################################################################################

EZEN=9.4
#% (range 7-13.2) Excretion rate (Warth, 2013)
ZEN_data=as.data.frame(read_excel("biomarcatori_PDI.xlsx",5))
names(ZEN_data)[5]=c("biomark")
Full_mat_ZEN=ZEN_data
data_ZEN_ls=list()
data_ZEN_ls$data_ZEN_tot=as.numeric(na.omit(Full_mat_ZEN$biomark))
saveRDS(data_ZEN_ls,"data_ZEN_ls.rds")



res_ZEN=list(
  ZEN_tot=fitdist(data_ZEN_ls$data_ZEN_tot,"norm"),
  ZEN_tot_e=fitdist(data_ZEN_ls$data_ZEN_tot,"exp")
)


df_res_ZEN=data.frame(names="ZEN_tot",do.call("rbind",lapply(res_ZEN,FUN=sumfit)))
row.names(df_res_ZEN)=NULL


png(paste0("ZEN_tot.png"))
denscomp(res_ZEN[c(1,2)],legendtext = c("Normal", "Exponential"),
         main = "Fitting ZEN biomarker full data", xlab = "microg/L")

dev.off()

res_pdi_ZEN=list()

temp_PDI=sapply(rexp(10000,df_res_ZEN$par[2]),FUN=function(x){ pdi_func(x,escr = mean(EZEN))})
res_pdi_ZEN[[1]]=as.numeric(c(t.test(temp_PDI)$estimate,t.test(temp_PDI)$conf.int))

df_pdi_ZEN=data.frame(name="ZEN_tot",do.call("rbind",res_pdi_ZEN))
names(df_pdi_ZEN) [2:4]=c("mean","conf.int.inf","conf.int.sup")


##############################################################################################################################


temp=rbind(df_pdi_DON,df_pdi_AFM1,df_pdi_FB,df_pdi_OTA,df_pdi_ZEN)
temp_fit=rbind(df_res_DON,df_res_AFM1,df_res_FB,df_res_OTA,df_res_ZEN)

file.remove("PDI_stat.xls")
XLConnect::writeWorksheetToFile("PDI_stat.xls",temp,"PDI")
XLConnect::writeWorksheetToFile("PDI_stat.xls",temp_fit,"fit stats")
##############################################################################################################################



