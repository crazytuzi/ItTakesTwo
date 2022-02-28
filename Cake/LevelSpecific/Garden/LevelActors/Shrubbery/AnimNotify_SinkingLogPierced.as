UCLASS(NotBlueprintable, meta = ("SinkingLogPierced (time marker)"))
class UAnimNotify_SinkingLogPierced : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SinkingLogPierced (time marker)";
	}
}

UCLASS(NotBlueprintable, meta = ("SinkingLogPiercedEnd (time marker)"))
class UAnimNotify_SinkingLogPiercedEnd : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SinkingLogPiercedEnd (time marker)";
	}
}


UCLASS(NotBlueprintable, meta = ("SinkingLogRetract (time marker)"))
class UAnimNotify_SinkingLogRetract : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SinkingLogRetract (time marker)";
	}
}

UCLASS(NotBlueprintable, meta = ("HammerLogHit (time marker)"))
class UAnimNotify_HammerLogHit : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HammerLogHit (time marker)";
	}
}