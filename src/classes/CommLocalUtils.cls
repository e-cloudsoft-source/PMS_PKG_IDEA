public with sharing class CommLocalUtils {
	
	private static Map<String,String> localeToDateTimeFmtMap;
	
	public static Map<String,String> getLocaleToDateTimeFmtMap () {
	    if (localeToDateTimeFmtMap == null)
	        localeToDateTimeFmtMap  = new Map<String,String> {
        	/*
            'ar'            => 'dd/MM/yyyy hh:mm a',
            'ar_AE'         => 'dd/MM/yyyy hh:mm a',
            'ar_BH'         => 'dd/MM/yyyy hh:mm a',
            'ar_JO'         => 'dd/MM/yyyy hh:mm a',
            'ar_KW'         => 'dd/MM/yyyy hh:mm a',
            'ar_LB'         => 'dd/MM/yyyy hh:mm a',
            'ar_SA'         => 'dd/MM/yyyy hh:mm a',
            'bg_BG'         => 'yyyy-M-d H:mm',
            'ca'            => 'dd/MM/yyyy HH:mm',
            'ca_ES'         => 'dd/MM/yyyy HH:mm',
            'ca_ES_EURO'    => 'dd/MM/yyyy HH:mm',
            'cs'            => 'd.M.yyyy H:mm',
            'cs_CZ'         => 'd.M.yyyy H:mm',
            'da'            => 'dd-MM-yyyy HH:mm',
            'da_DK'         => 'dd-MM-yyyy HH:mm',
            'de'            => 'dd.MM.yyyy HH:mm',
            'de_AT'         => 'dd.MM.yyyy HH:mm',
            'de_AT_EURO'    => 'dd.MM.yyyy HH:mm',
            'de_CH'         => 'dd.MM.yyyy HH:mm',
            'de_DE'         => 'dd.MM.yyyy HH:mm',
            'de_DE_EURO'    => 'dd.MM.yyyy HH:mm',
            'de_LU'         => 'dd.MM.yyyy HH:mm',
            'de_LU_EURO'    => 'dd.MM.yyyy HH:mm',
            'el_GR'         => 'd/M/yyyy h:mm a',
            'en_AU'         => 'd/MM/yyyy HH:mm',
            'en_B'          => 'M/d/yyyy h:mm a',
            'en_BM'         => 'M/d/yyyy h:mm a',
            'en_CA'         => 'dd/MM/yyyy h:mm a',
            'en_GB'         => 'dd/MM/yyyy HH:mm',
            'en_GH'         => 'M/d/yyyy h:mm a',
            'en_ID'         => 'M/d/yyyy h:mm a',
            */
            'en_IN'			=> 'd/M/yyyy h:mm tt',
            /*
            'en_IE'         => 'dd/MM/yyyy HH:mm',
            'en_IE_EURO'    => 'dd/MM/yyyy HH:mm',
            'en_NZ'         => 'd/MM/yyyy HH:mm',
            'en_SG'         => 'M/d/yyyy h:mm a',
            */
            'en_US'         => 'M/d/yyyy h:mm tt',
            /*
            'en_ZA'         => 'yyyy/MM/dd hh:mm a',
            'es'            => 'd/MM/yyyy H:mm',
            'es_AR'         => 'dd/MM/yyyy HH:mm',
            'es_BO'         => 'dd-MM-yyyy hh:mm a',
            'es_CL'         => 'dd-MM-yyyy hh:mm a',
            'es_CO'         => 'd/MM/yyyy hh:mm a',
            'es_CR'         => 'dd/MM/yyyy hh:mm a',
            'es_EC'         => 'dd/MM/yyyy hh:mm a',
            'es_ES'         => 'd/MM/yyyy H:mm',
            'es_ES_EURO'    => 'd/MM/yyyy H:mm',
            'es_GT'         => 'd/MM/yyyy hh:mm a',
            'es_HN'         => 'MM-dd-yyyy hh:mm a',
            'es_MX'         => 'd/MM/yyyy hh:mm a',
            'es_PE'         => 'dd/MM/yyyy hh:mm a',
            'es_PR'         => 'MM-dd-yyyy hh:mm a',
            'es_PY'         => 'dd/MM/yyyy hh:mm a',
            'es_SV'         => 'MM-dd-yyyy hh:mm a',
            'es_UY'         => 'dd/MM/yyyy hh:mm a',
            'es_VE'         => 'dd/MM/yyyy hh:mm a',
            'et_EE'         => 'd.MM.yyyy H:mm',
            'fi'            => 'd.M.yyyy H:mm',
            'fi_FI'         => 'd.M.yyyy H:mm',
            'fi_FI_EURO'    => 'd.M.yyyy H:mm',
            'fr'            => 'dd/MM/yyyy HH:mm',
            'fr_BE'         => 'd/MM/yyyy H:mm',
            'fr_CA'         => 'yyyy-MM-dd HH:mm',
            'fr_CH'         => 'dd.MM.yyyy HH:mm',
            'fr_FR'         => 'dd/MM/yyyy HH:mm',
            'fr_FR_EURO'    => 'dd/MM/yyyy HH:mm',
            'fr_LU'         => 'dd/MM/yyyy HH:mm',
            'fr_MC'         => 'dd/MM/yyyy HH:mm',
            'hr_HR'         => 'yyyy.MM.dd HH:mm',
            'hu'            => 'yyyy.MM.dd. H:mm',
            'hy_AM'         => 'M/d/yyyy h:mm a',
            'is_IS'         => 'd.M.yyyy HH:mm',
            'it'            => 'dd/MM/yyyy H.mm',
            'it_CH'         => 'dd.MM.yyyy HH:mm',
            'it_IT'         => 'dd/MM/yyyy H.mm',
            'iw'            => 'HH:mm dd/MM/yyyy',
            'iw_IL'         => 'HH:mm dd/MM/yyyy',
            */
            // JP
            'ja'            => 'yyyy/MM/dd HH:mm',
            'ja_JP'         => 'yyyy/MM/dd HH:mm',
            /*
            'kk_KZ'         => 'M/d/yyyy h:mm a',
            'km_KH'         => 'M/d/yyyy h:mm a',
            'ko'            => 'yyyy. M. d a h:mm',
            'ko_KR'         => 'yyyy. M. d a h:mm',
            'lt_LT'         => 'yyyy.M.d HH.mm',
            'lv_LV'         => 'yyyy.d.M HH:mm',
            'ms_MY'         => 'dd/MM/yyyy h:mm a',
            'nl'            => 'd-M-yyyy H:mm',
            'nl_BE'         => 'd/MM/yyyy H:mm',
            'nl_NL'         => 'd-M-yyyy H:mm',
            'nl_SR'         => 'd-M-yyyy H:mm',
            'no'            => 'dd.MM.yyyy HH:mm',
            'no_NO'         => 'dd.MM.yyyy HH:mm',
            'pl'            => 'yyyy-MM-dd HH:mm',
            'pt'            => 'dd-MM-yyyy H:mm',
            'pt_AO'         => 'dd-MM-yyyy H:mm',
            'pt_BR'         => 'dd/MM/yyyy HH:mm',
            'pt_PT'         => 'dd-MM-yyyy H:mm',
            'ro_RO'         => 'dd.MM.yyyy HH:mm',
            'ru'            => 'dd.MM.yyyy H:mm',
            'sk_SK'         => 'd.M.yyyy H:mm',
            'sl_SI'         => 'd.M.y H:mm',
            'sv'            => 'yyyy-MM-dd HH:mm',
            'sv_SE'         => 'yyyy-MM-dd HH:mm',
            */
            // THAI
            'th'            => 'd/M/yyyy, H:mm น.',
            'th_TH'         => 'd/M/yyyy, H:mm น.'
            /*
            'tr'            => 'dd.MM.yyyy HH:mm',
            'ur_PK'         => 'M/d/yyyy h:mm a',
            'vi_VN'         => 'HH:mm dd/MM/yyyy',
            'zh'            => 'yyyy-M-d ah:mm',
            'zh_CN'         => 'yyyy-M-d ah:mm',
            'zh_HK'         => 'yyyy-M-d ah:mm',
            'zh_TW'         => 'yyyy/M/d a h:mm'*/
        };
        return localeToDateTimeFmtMap;
	}
	// 指定する通貨のSymbolを取得する
	public static String getCurrencySymbol(String iso) { 
		String symbol = null;  
		if (iso=='ALL') { symbol='¥'; } 
		else if (iso=='USD') { symbol='$'; } 
		else if (iso=='ARS') { symbol='$'; } 
		else if (iso=='AWG') { symbol='ƒ'; } 
		else if (iso=='AUD') { symbol='$'; } 
		else if (iso=='BSD') { symbol='$'; } 
		else if (iso=='BBD') { symbol='$'; } 
		else if (iso=='BYR') { symbol='p.'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='BZD') { symbol='BZ$'; } 
		else if (iso=='BMD') { symbol='$'; } 
		else if (iso=='BOB') { symbol='$b'; } 
		else if (iso=='BAM') { symbol='KM'; } 
		else if (iso=='BWP') { symbol='P'; } 
		else if (iso=='BRL') { symbol='R$'; } 
		else if (iso=='GBP') { symbol='£'; } 
		else if (iso=='BND') { symbol='$'; } 
		else if (iso=='CAD') { symbol='$'; } 
		else if (iso=='KYD') { symbol='$'; } 
		else if (iso=='CLP') { symbol='$'; } 
		else if (iso=='CNY') { symbol='¥'; } 
		else if (iso=='COP') { symbol='$'; } 
		else if (iso=='CRC') { symbol='¢'; } 
		else if (iso=='HRK') { symbol='kn'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='CZK') { symbol='Kc'; } 
		else if (iso=='DKK') { symbol='kr'; } 
		else if (iso=='DOP') { symbol='RD$'; } 
		else if (iso=='XCD') { symbol='$'; } 
		else if (iso=='EGP') { symbol='£'; } 
		else if (iso=='SVC') { symbol='$'; } 
		else if (iso=='GBP') { symbol='£'; } 
		else if (iso=='EEK') { symbol='kr'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='FKP') { symbol='£'; } 
		else if (iso=='FJD') { symbol='$'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='GHC') { symbol='¢'; } 
		else if (iso=='GIP') { symbol='£'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='GTQ') { symbol='Q'; } 
		else if (iso=='GGP') { symbol='£'; } 
		else if (iso=='GYD') { symbol='$'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='HNL') { symbol='L'; } 
		else if (iso=='HKD') { symbol='$'; } 
		else if (iso=='HUF') { symbol='Ft'; } 
		else if (iso=='ISK') { symbol='kr'; } 
		else if (iso=='INR') { symbol='Rs.'; }
		else if (iso=='IDR') { symbol='Rp'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='IMP') { symbol='£'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='JMD') { symbol='J$'; } 
		else if (iso=='JPY') { symbol='¥'; } 
		else if (iso=='JEP') { symbol='£'; } 
		else if (iso=='LVL') { symbol='Ls'; }
		else if (iso=='LBP') { symbol='£'; } 
		else if (iso=='LRD') { symbol='$'; } 
		else if (iso=='CHF') { symbol='CHF'; } 
		else if (iso=='LTL') { symbol='Lt'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='MYR') { symbol='RM'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='MXN') { symbol='$'; } 
		else if (iso=='MZN') { symbol='MT'; } 
		else if (iso=='NAD') { symbol='$'; } 
		else if (iso=='ANG') { symbol='ƒ'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='NZD') { symbol='$'; } 
		else if (iso=='NIO') { symbol='C$'; } 
		else if (iso=='NOK') { symbol='kr'; } 
		else if (iso=='PAB') { symbol='B/.'; } 
		else if (iso=='PYG') { symbol='Gs'; } 
		else if (iso=='PEN') { symbol='S/.'; } 
		else if (iso=='PHP') { symbol='Php'; } 
		else if (iso=='PLN') { symbol='zl'; }
		else if (iso=='RON') { symbol='lei'; } 
		else if (iso=='SHP') { symbol='£'; } 
		else if (iso=='SGD') { symbol='$'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='SBD') { symbol='$'; } 
		else if (iso=='SOS') { symbol='S'; } 
		else if (iso=='ZAR') { symbol='R'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='SEK') { symbol='kr'; } 
		else if (iso=='CHF') { symbol='CHF'; } 
		else if (iso=='SRD') { symbol='$'; } 
		else if (iso=='SYP') { symbol='£'; } 
		else if (iso=='THB') { symbol='฿'; } 
		else if (iso=='TWD') { symbol='NT$'; } 
		else if (iso=='TTD') { symbol='TT$'; } 
		else if (iso=='TRY') { symbol='TL'; } 
		else if (iso=='TRL') { symbol='£'; } 
		else if (iso=='TVD') { symbol='$'; } 
		else if (iso=='GBP') { symbol='£'; } 
		else if (iso=='USD') { symbol='$'; } 
		else if (iso=='UYU') { symbol='$U'; } 
		else if (iso=='EUR') { symbol='€'; } 
		else if (iso=='VEF') { symbol='Bs'; } 
		else if (iso=='ZWD') { symbol='Z$'; }
		else if (iso=='KRW') { symbol='₩'; }
		else { symbol='¥'; } 
		return symbol; 
	}
}