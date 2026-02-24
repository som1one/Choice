import { Dimensions, StyleSheet } from "react-native";

const {width, height} = Dimensions.get('screen');

const styles = StyleSheet.create({
    button: {
      height: height/18,
      borderWidth: 0,
      backgroundColor: '#2D81E0',
      borderRadius: 10,
      justifyContent: 'center'
    },
    buttonText: {
      color: 'white',
      fontSize: 17,
      fontWeight: '500',
      alignSelf: 'center'
    },
    textInput: (isFocused, big) => { return {
      backgroundColor: '#f2f3f5',
      borderRadius: 10, 
      borderColor: isFocused ? '#3F8AE0' : '#d5d5d7', 
      borderWidth: 1, 
      height: big ? height/7 : height/18,
      paddingHorizontal: 15
    }},
    textInputBig: {
      backgroundColor: '#f2f3f5',
      borderRadius: 10, 
      borderColor: '#3F8AE0', 
      borderWidth: 1, 
      height: height/7,
      paddingHorizontal: 15
    },
    textInputError: (big) => { return {
      backgroundColor: '#FAEBEB',
      borderRadius: 10, 
      borderColor: '#E64646', 
      borderWidth: 1, 
      height: big ? height/7 : height/18,
      paddingHorizontal: 15
    }},
    textInputFont: {
      color: 'black',
      fontWeight: '400',
      fontSize: 16,
    },
    topRightCorner: {
      ...StyleSheet.absoluteFillObject,
      alignSelf: 'flex-end',
      marginTop: -5,
    }
});

export default styles;