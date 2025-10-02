//ApplicationInfo {
    //     name: "Asodya Admin".to_string(),
    //     description: "Access Admin Panel from Asodya.".to_string(),
    //     logo_image_url: "https://res.cloudinary.com/dhncdmb2t/image/upload/v1751705980/image_ff4hdh.png".to_string(),
    //     url_app: "https://admin.asodya.com".to_string(),
    //     two_fa_auth: false,
    //     primary_color: "#123456".to_string(),
    //     secondary_color: "#654321".to_string(),
    //     tertiary_color: "#abcdef".to_string(),
    //     quartary_color: None,
    //     created_at: chrono::Utc::now().to_rfc3339(),
    // }

class ApplicationInfo {
  final String name;
  final String description;
  final String logoImageUrl;
  final String urlApp;
  final bool twoFaAuth;
  final String primaryColor;
  final String secondaryColor;
  final String tertiaryColor;
  final String? quartaryColor;
  final String createdAt;

  ApplicationInfo({
    required this.name,
    required this.description,
    required this.logoImageUrl,
    required this.urlApp,
    required this.twoFaAuth,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    this.quartaryColor,
    required this.createdAt,
  });

  factory ApplicationInfo.fromJson(Map<String, dynamic> json) {
    return ApplicationInfo(
      name: json['name'],
      description: json['description'],
      logoImageUrl: json['logo_image_url'],
      urlApp: json['url_app'],
      twoFaAuth: json['two_fa_auth'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      tertiaryColor: json['tertiary_color'],
      quartaryColor: json['quartary_color'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logo_image_url': logoImageUrl,
      'url_app': urlApp,
      'two_fa_auth': twoFaAuth,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'tertiary_color': tertiaryColor,
      'quartary_color': quartaryColor,
      'created_at': createdAt,
    };
  }
}