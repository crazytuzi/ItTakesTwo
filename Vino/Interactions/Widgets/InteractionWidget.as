
class UInteractionWidget : UHazeUserWidget
{
	UPROPERTY()
	EHazeActivationType ActivationType;
    UPROPERTY()
    bool bIsTriggerAvailable = false;
    UPROPERTY()
    bool bIsTriggerFocused = false;
    UPROPERTY()
    bool bIsCodyOnlyTagged = false;
    UPROPERTY()
    bool bIsMayOnlyTagged = false;

	default bAttachToEdgeOfScreen = true;

	UFUNCTION(BlueprintPure)
	bool HasExclusivePlayer()
	{
		return bIsCodyOnlyTagged || bIsMayOnlyTagged;
	}

	UFUNCTION(BlueprintPure)
	EHazePlayer GetExclusivePlayer()
	{
		if (bIsCodyOnlyTagged)
			return EHazePlayer::Cody;
		else if (bIsMayOnlyTagged)
			return EHazePlayer::May;
		else
			return EHazePlayer::MAX;
	}

	UFUNCTION(BlueprintPure)
	bool IsWrongPlayerExclusive()
	{
		if (!SceneView::IsFullScreen())
		{
			if (bIsCodyOnlyTagged && Player != nullptr && Player.IsMay())
				return true;
			if (bIsMayOnlyTagged && Player != nullptr && Player.IsCody())
				return true;
		}
		return false;
	}

	void InitTrigger()
	{
		BP_InitTrigger();
	}

	UFUNCTION(BlueprintEvent)
	void BP_InitTrigger() {}
};