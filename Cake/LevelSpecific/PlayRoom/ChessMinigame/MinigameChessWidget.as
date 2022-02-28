
UCLASS(Abstract)
class UMinigameChessWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float TimeLeftWhitePlayer = 0;

	UPROPERTY(BlueprintReadOnly)
	float TimeLeftBlackPlayer = 0;

	UPROPERTY(BlueprintReadOnly)
	float MaxTime = 0;

	UPROPERTY(BlueprintReadOnly)
	EHazePlayer WhitePlayer = EHazePlayer::MAX;

	private EHazePlayer _CurrentPlayer = EHazePlayer::MAX;
	private float MessageTimeLeft = 0.f;
	private FText Message;
	
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if(MessageTimeLeft > 0)
		{
			MessageTimeLeft -= DeltaTime;
		}
	}

	void SetCurrentPlayer(EHazePlayer PlayerType) property
	{
		_CurrentPlayer = PlayerType;
		MessageTimeLeft = 0;
	}

	void SetActiveMessage(FText NewMessage, float Time)
	{
		Message = NewMessage;
		MessageTimeLeft = Time;
	}

	UFUNCTION(BlueprintPure)
	bool GetMessage(UTextBlock TextBlock)const
	{
		if(MessageTimeLeft > 0)
		{
			TextBlock.SetText(Message);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetTimeAlphaForPlayer(EHazePlayer ForPlayer) const
	{
		if(MaxTime <= 0)
			return 0.f;
		else if(ForPlayer == WhitePlayer)
			return TimeLeftWhitePlayer / MaxTime;
		else
			return TimeLeftBlackPlayer / MaxTime;
	}

	UFUNCTION(BlueprintPure)
	FString GetTimeTextForPlayer(EHazePlayer ForPlayer)
	{
		if(MaxTime <= 0)
			return GetTextForTime(0);
		else if(ForPlayer == WhitePlayer)
			return GetTextForTime(TimeLeftWhitePlayer);
		else
			return GetTextForTime(TimeLeftBlackPlayer);

	}

	FString GetTextForTime(float Time)
	{
		if(Time <= 0)
			return FString("");

		int Minutes = FMath::FloorToInt(Time / 60.f);
		FString MinutesText = "";
		if(Minutes < 10)
			MinutesText += "0";
		MinutesText += Minutes;

		int Seconds = FMath::FloorToInt(Time - (Minutes * 60));
		FString SecondsText = "";
		if(Seconds < 10)
			SecondsText += "0";
		SecondsText += Seconds;

		int MicroSeconds = FMath::FloorToInt((Time - (Minutes * 60) - Seconds) * 10);
		FString MicroSecondsText = "";
		if(MicroSeconds < 10)
			MicroSecondsText += "0";
		MicroSecondsText += MicroSeconds;

		return FString(MinutesText + "." + SecondsText + "." + MicroSecondsText);
	}

	UFUNCTION(BlueprintPure)
	FString GetActivePlayerName(EHazePlayer ForPlayer)const
	{
		if(_CurrentPlayer == EHazePlayer::Cody)
			return "Cody";
		else if(_CurrentPlayer == EHazePlayer::May)
			return "May";
		else
			return "";
	}
}