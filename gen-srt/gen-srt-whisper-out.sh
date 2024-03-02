#!/bin/bash

# 读取环境变量
source .env

# 输入的视频文件路径
VIDEO_FILE_PATH=\$1

# 跳过的步骤数
SKIP_STEP=\$2

# 提取音频并转换为wav格式
AUDIO_FILE_PATH="${VIDEO_FILE_PATH%.*}.wav"
if [ "$SKIP_STEP" -lt 1 ]; then
	echo "Starting audio extraction: ffmpeg -i $VIDEO_FILE_PATH -hide_banner -vn -loglevel error -ar 16000 -ac 1 -c:a pcm_s16le -y $AUDIO_FILE_PATH"
	START=$(date +%s)
	ffmpeg -i "$VIDEO_FILE_PATH" -hide_banner -vn -ar 16000 -ac 1 -c:a pcm_s16le -y "$AUDIO_FILE_PATH" -progress -
	if [ $? -ne 0 ]; then
		echo "Error: Failed to extract audio from video."
		exit 1
	fi
	END=$(date +%s)
	DIFF=$(($END - $START))
	echo "Audio extraction completed in $DIFF seconds."
else
	echo "Skipping audio extraction step."
fi

# 使用whisper生成srt字幕文件
WHISPER_OUTPUT=$(mktemp)
if [ "$SKIP_STEP" -lt 2 ]; then
	echo "Starting srt generation: $WHISPER_PATH -m $WHISPER_MODEL -l $WHISPER_LANGUAGE -f $AUDIO_FILE_PATH -t 8 -osr"
	START=$(date +%s)
	$WHISPER_PATH -m $WHISPER_MODEL -l $WHISPER_LANGUAGE -f "$AUDIO_FILE_PATH" -t "8" -osrt >"$WHISPER_OUTPUT"
	if [ $? -ne 0 ]; then
		echo "Error: Failed to generate srt file."
		exit 1
	fi
	END=$(date +%s)
	DIFF=$(($END - $START))
	echo "Srt generation completed in $DIFF seconds."
else
	echo "Skipping srt generation step."
fi

# 从whisper的输出中提取srt文件名
SRT_FILE_PATH=$(grep -oP "saving output to '\K[^']*[^']" "$WHISPER_OUTPUT")
rm "$WHISPER_OUTPUT"

# 使用ChatGPT翻译字幕
TRANSLATED_SRT_FILE_PATH="${AUDIO_FILE_PATH%.*}.out_${TRANSLATOR_TO_LANGUAGE}.srt"
if [ "$SKIP_STEP" -lt 3 ]; then
	echo "Starting srt translation: cli/translator.mjs --stream --temperature 0 --from $WHISPER_LANGUAGE --to $TRANSLATOR_TO_LANGUAGE --file $SRT_FILE_PATH"
	START=$(date +%s)
	pushd $TRANSLATOR_PATH
	cli/translator.mjs --stream --temperature 0 --from "$WHISPER_LANGUAGE" --to "$TRANSLATOR_TO_LANGUAGE" --file "$SRT_FILE_PATH"
	popd
	if [ $? -ne 0 ]; then
		echo "Error: Failed to translate srt file."
		exit 1
	fi
	END=$(date +%s)
	DIFF=$(($END - $START))
	echo "Srt translation completed in $DIFF seconds."
else
	echo "Skipping srt translation step."
fi

# 重命名输出文件
FINAL_SRT_FILE_PATH="${AUDIO_FILE_PATH%.*}.chs.srt"
if [ "$SKIP_STEP" -lt 4 ]; then
	echo "Starting file renaming: mv $TRANSLATED_SRT_FILE_PATH $FINAL_SRT_FILE_PATH"
	START=$(date +%s)
	mv "$TRANSLATED_SRT_FILE_PATH" "$FINAL_SRT_FILE_PATH"
	if [ $? -ne 0 ]; then
		echo "Error: Failed to rename srt file."
		exit 1
	fi
	END=$(date +%s)
	DIFF=$(($END - $START))
	echo "File renaming completed in $DIFF seconds."
else
	echo "Skipping file renaming step."
fi

# 删除wav文件
if [ "$SKIP_STEP" -lt 5 ]; then
	echo "Deleting wav file: rm $AUDIO_FILE_PATH"
	rm "$AUDIO_FILE_PATH"
	if [ $? -ne 0 ]; then
		echo "Error: Failed to delete wav file."
		exit 1
	fi
else
	echo "Skipping wav file deletion step."
fi

echo "Subtitle generation completed successfully."
