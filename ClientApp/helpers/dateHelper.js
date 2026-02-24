const formatDate = (date) => {
    let dateElements = date.split('T');
    let utc = dateElements[0];
    
    let time = dateElements[1].split(':');

    return `${utc} ${Number.parseInt(time[0])}:${time[1]}:${time[2].split('.')[0]}`.split('Z')[0];
}

const getTimeFromString = (timeString) => {
    let dateElements = timeString.split('T');

    let time = dateElements[1].split(':');

    return `${Number.parseInt(time[0])}:${time[1]}`;
}

const getMonthAndDayFromString = (dateString) => {
    let dateElements = dateString.split('T');
    let ymd = dateElements[0].split('-');

    return `${ymd[2]}.${ymd[1]}`;
}

const getDateFromString = (dateString) => {
    let dateElements = dateString.split('T');

    return dateElements[0];
}

const convertDateToString = (date) => {
    let year = date.getFullYear();
    let month = date.getUTCMonth()+1;
    let day = date.getDate();

    return `${day < 10 ? '0'+day : day}.${month < 10 ? '0'+month : month}.${year}`;
}

const convertTimeToString = (time) => {
    let minutes = time.getMinutes();
    let hours = time.getHours();

    return `${hours < 10 ? '0'+hours : hours}:${minutes < 10 ? '0'+minutes : minutes}`;
}

const convertDateToJson = (date, time) => {
    let newDate = date.split('.');

    return `${newDate[2]}-${newDate[1]}-${newDate[0]}T${time}:00.000Z`;
}

const convertFullDateToJson = (date) => {
    let year = date.getFullYear();
    let month = date.getUTCMonth()+1;
    let day = date.getDate();
    let minutes = date.getMinutes();
    let hours = date.getHours();

    return `${year}-${month < 10 ? '0'+month : month}-${day < 10 ? '0'+day : day}T${hours < 10 ? '0'+hours : hours}:${minutes < 10 ? '0'+minutes : minutes}:00.000Z`;
}

const getDifference = (json) => {
    let today = new Date();
    let difference = Math.abs((today-Math.abs(today.getTimezoneOffset()/60))-new Date(json));

    const seconds = difference / 1000;
    if (seconds < 0) {
        return 'только что';
    } else if (seconds < 60) {
        return `${Math.floor(seconds)} секунд`;
    }

    const minutes = seconds / 60;
    if (minutes < 60) {
        const minutesRounded = Math.floor(minutes);
        return minutesRounded === 1 ? 'минуту' : `${minutesRounded} минуты`;
    }

    const hours = minutes / 60;
    if (hours < 24) {
        const hoursRounded = Math.floor(hours);
        return hoursRounded === 1 ? 'час' : `${hoursRounded} часов`;
    }

    const days = hours / 24;
    const daysRounded = Math.floor(days);
    return daysRounded === 1 ? 'день' : `${daysRounded} дней`;
}

export default {
    formatDate,
    convertDateToString,
    convertTimeToString,
    convertDateToJson,
    getTimeFromString,
    getDateFromString,
    convertFullDateToJson,
    getMonthAndDayFromString,
    getDifference
}
