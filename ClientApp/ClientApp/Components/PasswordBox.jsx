import React from "react";
import {
    View,
    TextInput,
    TouchableOpacity
} from 'react-native';
import styles from "../Styles";
import { Icon } from "react-native-elements";

const PasswordBox = ({value, changed, placeholder, error}) => {
    placeholder = placeholder == undefined ? 'Пароль' : placeholder;
    error = error == undefined ? false : error;

    const [hidden, setHidden] = React.useState(true);
    const [isFocused, setIsFocused] = React.useState(false);

    return (
        <View
            style={[error ? styles.textInputError(false) : styles.textInput(isFocused, false), {
                flexDirection: 'row'
            }]}>
            <TextInput
                style={[styles.textInputFont, {
                    flex: 1,
                    alignSelf: 'center'
                }]}
                secureTextEntry={hidden}
                placeholder={placeholder}
                value={value}
                onChangeText={(v) => changed(v)}
                onFocus={(e) => setIsFocused(true)}
                onBlur={(e) => setIsFocused(false)}/>

            <TouchableOpacity
                style={{
                    alignSelf: 'center'
                }}
                onPress={() => setHidden(prev => !prev)}>
                <Icon 
                    type='material-community'
                    color='gray'
                    name={hidden ? 'eye' : 'eye-off'}/>
            </TouchableOpacity>
        </View>
    )
}

export default PasswordBox;