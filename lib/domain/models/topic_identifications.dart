// from dataclasses import asdict, dataclass, field

// @dataclass
// class IdentificationsModel:
//     input_identification: str
//     title_identification: str | None = field(default=None)
//     # description_identification: str | None = field(default=None)
//     link_identification: str | None = field(default=None)
//     img_link_identification: str | None = field(default=None)



class Identifications {
  String inputIdentification;
  String? titleIdentification;
  // String? descriptionIdentification;
  String? linkIdentification;
  String? imgLinkIdentification;

  Identifications({
    required this.inputIdentification,
    this.titleIdentification,
    // this.descriptionIdentification,
    this.linkIdentification,
    this.imgLinkIdentification,
  });

  factory Identifications.fromJson(Map<String, dynamic> json) {
    return Identifications(
      inputIdentification: json['input_identification'] as String,
      titleIdentification: json['title_identification'] as String?,
      // descriptionIdentification: json['description_identification'] as String?,
      linkIdentification: json['link_identification'] as String?,
      imgLinkIdentification: json['img_link_identification'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input_identification': inputIdentification,
      'title_identification': titleIdentification,
      // 'description_identification': descriptionIdentification,
      'link_identification': linkIdentification,
      'img_link_identification': imgLinkIdentification,
    };
  }

  @override
  String toString() {
    return 'Identifications(inputIdentification: $inputIdentification, titleIdentification: $titleIdentification, linkIdentification: $linkIdentification, imgLinkIdentification: $imgLinkIdentification)';
  }
}



class PdfInputInfo {
  final int pages;
  final String? pdfUrl;
  const PdfInputInfo({required this.pages, this.pdfUrl});
}


class   PdfContextInfo {
  final String message;
  final Map<String, dynamic> data;
  final int statusCode;
  const PdfContextInfo({
    required this.message,
    required this.data,
    required this.statusCode,
  });

  factory PdfContextInfo.fromJson(Map<String, dynamic> json) {
    return PdfContextInfo(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      statusCode: json['status_code'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data,
      'status_code': statusCode,
    };
  }

}