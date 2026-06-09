class Song {
  final String artist;
  final String title;
  final String lyrics;
  final String genre;
  final String album;
  final String releaseDate;
  final bool explicit;

  final double energy;
  final double danceability;
  final double positiveness;
  final double tempo;
  final double loudness;
  final double speechiness;
  final double liveness;
  final double acousticness;
  final double instrumentalness;
  final double popularity;

  Song({
    required this.artist,
    required this.title,
    required this.lyrics,
    required this.genre,
    required this.album,
    required this.releaseDate,
    required this.explicit,
    required this.energy,
    required this.danceability,
    required this.positiveness,
    required this.tempo,
    required this.loudness,
    required this.speechiness,
    required this.liveness,
    required this.acousticness,
    required this.instrumentalness,
    required this.popularity,
  });

  factory Song.fromMap(Map<String,dynamic> map){
    return Song(
      artist: map['Artist(s)'] ?? '',
      title: map['song'] ?? '',
      lyrics: map['lyrics'] ?? '',
      genre: map['Genre'] ?? '',
      album: map['Album'] ?? '',
      releaseDate: map['Release Date'] ?? '',
      explicit: map['Explicit'] == 0,
      energy: double.tryParse(map['Energy'].toString(),) ?? 0,
      danceability: double.tryParse(map['Danceability'].toString(),) ?? 0,
      positiveness: double.tryParse(map['Positiveness'].toString(),) ?? 0,
      tempo: double.tryParse(map['Tempo'].toString(),) ?? 0,
      loudness: double.tryParse(map['Loudness (db)'].toString(),) ?? 0,
      speechiness: double.tryParse(map['Speechiness'].toString(),) ?? 0,
      liveness: double.tryParse(map['Liveness'].toString(),) ?? 0,
      acousticness: double.tryParse(map['Acousticness'].toString(),) ?? 0,
      instrumentalness: double.tryParse(map['Instrumentalness'].toString(),) ?? 0,
      popularity: double.tryParse(map['Popularity'].toString(),) ?? 0,
    );
  }
}