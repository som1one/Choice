import React from "react";
import {
    View,
    TextInput,
} from 'react-native';
import styles from "../Styles";

const CustomTextInput = ({value, changed, placeholder, readonly, error, big, type, max, multiline}) => {
    readonly = readonly == undefined ? false : readonly;
    error = error == undefined ? false : error;
    big = big == undefined ? false : big;
    type = type == undefined ? 'default' : type;
    max = max == undefined ? 150 : max;
    placeholder = placeholder == undefined ? '' : placeholder;
    multiline = multiline == undefined ? false : multiline;

    const [isFocused, setIsFocused] = React.useState(false);

    return (
        <View
            style={error ? styles.textInputError(big) : styles.textInput(isFocused, big)}>
            <TextInput
                style={styles.textInputFont}
                maxLength={max}
                readOnly={readonly}
                placeholder={placeholder}
                onFocus={(e) => setIsFocused(true)}
                onBlur={(e) => setIsFocused(false)}
                value={value}
                onChangeText={(v) => changed(v)}
                keyboardType={type}
                multiline={multiline}/>
        </View>
    )
}

export default CustomTextInput;