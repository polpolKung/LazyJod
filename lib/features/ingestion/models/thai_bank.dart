import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum ThaiBank {
  kbank,
  scb,
  ktb,
  ttb,
  bbl,
  gsb,
  bay,
  baac,
  kkp,
  cimb,
  uob,
  tisco,
  lhb,
  ghb,
  trueMoney,
  promptPay,
  unknown;

  String get displayNameThai {
    switch (this) {
      case ThaiBank.kbank: return 'กสิกรไทย (K PLUS)';
      case ThaiBank.scb: return 'ไทยพาณิชย์ (SCB EASY)';
      case ThaiBank.ktb: return 'กรุงไทย (Krungthai NEXT)';
      case ThaiBank.ttb: return 'ทีทีบี (ttb touch)';
      case ThaiBank.bbl: return 'กรุงเทพ (Bualuang m)';
      case ThaiBank.gsb: return 'ออมสิน (MyMo)';
      case ThaiBank.bay: return 'กรุงศรี (KMA)';
      case ThaiBank.baac: return 'ธ.ก.ส. (A-Mobile)';
      case ThaiBank.kkp: return 'เกียรตินาคินภัทร (KKP Mobile)';
      case ThaiBank.cimb: return 'ซีไอเอ็มบี ไทย (CIMB)';
      case ThaiBank.uob: return 'ยูโอบี (UOB TMRW)';
      case ThaiBank.tisco: return 'ทิสโก้ (TISCO)';
      case ThaiBank.lhb: return 'แลนด์ แอนด์ เฮ้าส์ (LHB You)';
      case ThaiBank.ghb: return 'อาคารสงเคราะห์ (GHB ALL)';
      case ThaiBank.trueMoney: return 'ทรูมันนี่ (TrueMoney)';
      case ThaiBank.promptPay: return 'พร้อมเพย์ (PromptPay)';
      case ThaiBank.unknown: return 'ธนาคารทั่วไป / ไม่ระบุ';
    }
  }

  String get shortCode {
    switch (this) {
      case ThaiBank.kbank: return 'KBANK';
      case ThaiBank.scb: return 'SCB';
      case ThaiBank.ktb: return 'KTB';
      case ThaiBank.ttb: return 'TTB';
      case ThaiBank.bbl: return 'BBL';
      case ThaiBank.gsb: return 'GSB';
      case ThaiBank.bay: return 'BAY';
      case ThaiBank.baac: return 'BAAC';
      case ThaiBank.kkp: return 'KKP';
      case ThaiBank.cimb: return 'CIMB';
      case ThaiBank.uob: return 'UOB';
      case ThaiBank.tisco: return 'TISCO';
      case ThaiBank.lhb: return 'LHB';
      case ThaiBank.ghb: return 'GHB';
      case ThaiBank.trueMoney: return 'TrueMoney';
      case ThaiBank.promptPay: return 'PromptPay';
      case ThaiBank.unknown: return 'OTHER';
    }
  }

  Color get brandColor {
    switch (this) {
      case ThaiBank.kbank: return AppColors.bankKBank;
      case ThaiBank.scb: return AppColors.bankSCB;
      case ThaiBank.ktb: return AppColors.bankKTB;
      case ThaiBank.ttb: return AppColors.bankTTB;
      case ThaiBank.bbl: return AppColors.bankBBL;
      case ThaiBank.gsb: return AppColors.bankGSB;
      case ThaiBank.bay: return AppColors.bankBAY;
      case ThaiBank.baac: return AppColors.bankBAAC;
      case ThaiBank.kkp: return AppColors.bankKKP;
      case ThaiBank.cimb: return AppColors.bankCIMB;
      case ThaiBank.uob: return AppColors.bankUOB;
      case ThaiBank.tisco: return AppColors.bankTISCO;
      case ThaiBank.lhb: return AppColors.bankLHB;
      case ThaiBank.ghb: return AppColors.bankGHB;
      case ThaiBank.trueMoney: return AppColors.bankTrueMoney;
      case ThaiBank.promptPay: return AppColors.bankPromptPay;
      case ThaiBank.unknown: return Colors.grey;
    }
  }

  List<String> get detectionKeywords {
    switch (this) {
      case ThaiBank.kbank:
        return ['k plus', 'kplus', 'kasikorn', 'กสิกร', 'kbank', '004'];
      case ThaiBank.scb:
        return ['scb easy', 'scbeasy', 'siam commercial', 'ไทยพาณิชย์', '014', 'scb'];
      case ThaiBank.ktb:
        return ['krungthai next', 'krungthai', 'กรุงไทย', '006', 'เป๋าตัง'];
      case ThaiBank.ttb:
        return ['ttb touch', 'ttb', 'tmb', 'thanachart', 'ทหารไทยธนชาต', '011'];
      case ThaiBank.bbl:
        return ['bangkok bank', 'bualuang', 'บัวหลวง', 'กรุงเทพ', '002', 'm banking'];
      case ThaiBank.gsb:
        return ['mymo', 'gsb', 'ออมสิน', 'ธนาคารออมสิน', '030'];
      case ThaiBank.bay:
        return ['kma', 'krungsri', 'กรุงศรี', 'อยุธยา', '025'];
      case ThaiBank.baac:
        return ['a-mobile', 'baac', 'ธ.ก.ส.', 'เพื่อการเกษตร', '034'];
      case ThaiBank.kkp:
        return ['kkp mobile', 'kiatnakin', 'เกียรตินาคิน', '069'];
      case ThaiBank.cimb:
        return ['cimb thai', 'cimb', 'ซีไอเอ็มบี', '022'];
      case ThaiBank.uob:
        return ['uob tmrw', 'uob', 'ยูโอบี', '024'];
      case ThaiBank.tisco:
        return ['tisco', 'ทิสโก้', '067'];
      case ThaiBank.lhb:
        return ['lhb you', 'lh bank', 'แลนด์ แอนด์ เฮ้าส์', '073'];
      case ThaiBank.ghb:
        return ['ghb all', 'gh bank', 'อาคารสงเคราะห์', 'ธอส', '033'];
      case ThaiBank.trueMoney:
        return ['truemoney', 'true money', 'ทรูมันนี่', 'วอลเล็ท'];
      case ThaiBank.promptPay:
        return ['promptpay', 'พร้อมเพย์', 'qr payment', 'thai qr payment', 'สแกนจ่าย'];
      case ThaiBank.unknown:
        return [];
    }
  }
}
