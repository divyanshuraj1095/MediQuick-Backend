const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema (
{
 name : {
    type : String,
    required : [true, 'Username is required !!'],
    trim : true,
 },
 email : {
    type : String,
    required : [true, 'E-mail is required!!'],
    unique : true,
    lowercase : true,
 },
 phone : {
    type : String,
 },
 password : {
    type : String,
    required : [true, 'Password is required!!'],
    minlength : 6,
    select : false,
 },
 role : {
    type : String,
    enum : ['user','admin','pharmacy'],
    default : 'user',
 },
 address : {
    type : String,
 },
 createdAt : {
    type : Date,
    default : Date.now,
 },
},
{
    timestamps : true
}
);

userSchema.pre('save', async function (){
    if(!this.isModified("password")) return;

    this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.comparePassword = async function (enteredPassword){
    return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model("User", userSchema);