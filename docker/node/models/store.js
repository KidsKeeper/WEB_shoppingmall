let mongoose = require('mongoose');
let Schema = mongoose.Schema;

let storeSchema = new Schema({
    bizesNm: String, // 상호명
    indsSclsNm: String, // 상권업종소분류먕
    lnoAdr: String, // 지번주소
    rdnm: String, // 도로명
    rdnmAdr: String, // 도로명주소
    lon: String, // 경도
    lat: String // 위도
}, { collection: 'store' });

module.exports = mongoose.model( 'store', storeSchema );