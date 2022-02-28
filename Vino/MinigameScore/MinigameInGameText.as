enum EMinigameTextMovementType
{
	Static,
	ConstantIndefinite,
	AccelerateIndefinite,
	ConstantToHeight,
	DeccelerateIndefinite,
	DeccelerateToHeight,
	AccelerateToHeight
};

enum EMinigameHazeTextSize
{
	ExtraLarge,
	SmallText,
	Regular
};

enum EMinigameTextPlayerTarget
{
	May,
	Cody,
	Both
};

//PURELY VISUAL
enum EInGameTextJuice
{
	NoChange,
	SmallChange,
	BigChange,
	NegativeChange
};

enum EMinigameTextColor
{
	Default,
	Disabled,
	Cody,
	May,
	Attention,
	Red
}

class UMinigameInGameText : UHazeUserWidget
{
	//*** SETUP ***//
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector SpawnLocation;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D LocationSpawnArea = FVector2D(80, 20);

	EMinigameTextMovementType MinigameTextMovementType; 

	EMinigameTextPlayerTarget MinigameTextPlayerSetting;
	
	EMinigameTextColor MinigameTextColor;

	FVector CurrentPosition;

	float TimeDuration = 3.f;
	float FadeDuration = 2.f;
	float TargetHeight = 30.f;
	float MoveSpeed = 100.f;
	int TextSize = 35.f;
	bool bIsPooled;
	
	EMinigameHazeTextSize MinigameHazeTextSize;

	//*** VALUES ***//

	FVector CameraRight;
	FVector CameraUp;
	FVector LocationRightOffset;
	FVector LocationUpOffset;

	float CurrentDuration;
	float CurrentFade;
	float AccelerationSpeed = 0.1f;
	float MaxHeight;

	float DefaultScale = 1.f;
	float XScale;
	float YScale;	

	float TargetXScale;
	float TargetYScale;

	float MaxTargetScale = 0.7f;

	int MaxBounce = 4;
	int CurrentBounce;

	float InterpSpeed = 12.f;
	float InterpMultiplier = 0.975;

	bool bBouncePositive;
	float NegativeDirectionMultiplier = 4.f;

	FHazeConstrainedPhysicsValue PhysicsValue;

	void SetTextValue(int Score)
	{
		FText InText = FText::FromString("+" + Score);
		BP_SetTextValue(InText);
	}

	void SetTextValue(FString StingValue)
	{
		FText InText = FText::FromString(StingValue);
		BP_SetTextValue(InText);
	}

	void SetScale(float XScale, float YScale)
	{
		BP_SetTextScale(XScale, YScale);
	}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = SetValue))
	void BP_SetTextValue(FText Text) {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = SetOpacity))
	void BP_SetTextOpacity(float Opacity) {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = SetSize))
	void BP_SetTextSize(int Size) {} 

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = SetScale))
	void BP_SetTextScale(float XScale, float YScale) {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = Reset))
	void BP_Reset() {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = TextJuice))
	void BP_TextJuice(EInGameTextJuice InGameTextJuice) {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = TextColor))
	void BP_TextColor(EMinigameTextColor TextColor) {}

	void Start(EInGameTextJuice InGameTextJuice)
	{
		CameraRight = Player.GetPlayerViewRotation().RotateVector(FVector::RightVector);
		CameraUp = Player.GetPlayerViewRotation().RotateVector(FVector::UpVector);

		LocationRightOffset = CameraRight * FMath::RandRange(-LocationSpawnArea.X * 0.5f, LocationSpawnArea.X * 0.5f);
		LocationUpOffset = CameraUp * FMath::RandRange(-LocationSpawnArea.Y * 0.5f, LocationSpawnArea.Y * 0.5f);

        // CurrentPosition = SpawnLocation + LocationRightOffset + LocationUpOffset;
        CurrentPosition = SpawnLocation + CameraRight + CameraUp;
		Print("CurrentPosition: " + CurrentPosition);
        SetWidgetWorldPosition(CurrentPosition);

		CurrentDuration = TimeDuration;
		CurrentFade = FadeDuration;
		MaxHeight = CurrentPosition.Z + TargetHeight;

		XScale = DefaultScale * 0.15f;
		YScale = DefaultScale * 0.15f;

		bBouncePositive = true;
		CurrentBounce = 1;

		BP_TextColor(MinigameTextColor);

		BP_TextJuice(InGameTextJuice);
	}

	UFUNCTION(BlueprintOverride)
    void Tick(FGeometry MyGeometry, float DeltaTime)
    {
		//Check if off screen
		FVector2D OutParam;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, CurrentPosition, OutParam);

		if (OutParam.X < 0.f || OutParam.Y < 0.f)
		{
			Player.RemoveWidget(this);
			return;
		}

		switch(MinigameTextMovementType)
		{
			case EMinigameTextMovementType::AccelerateIndefinite: AccelerateIndefinite(DeltaTime); break;
			case EMinigameTextMovementType::AccelerateToHeight: AccelerateToHeight(DeltaTime); break;
			case EMinigameTextMovementType::ConstantIndefinite: ConstantIndefinite(DeltaTime); break;
			case EMinigameTextMovementType::ConstantToHeight: ConstantToHeight(DeltaTime); break;
			case EMinigameTextMovementType::DeccelerateIndefinite: DeccelerateIndefinite(DeltaTime); break;
			case EMinigameTextMovementType::DeccelerateToHeight: DeccelerateToHeight(DeltaTime); break;
			case EMinigameTextMovementType::Static: break;
		}

		Bounciness(DeltaTime);

		CurrentDuration -= DeltaTime;

		if (CurrentDuration > 0.f)
			return;
		
		CurrentFade -= DeltaTime;

		float Opacity = CurrentFade / FadeDuration;
		BP_SetTextOpacity(Opacity);

		if (CurrentFade > 0.f)
			return;

		Player.RemoveWidget(this);
    }

	void AccelerateIndefinite(float DeltaTime)
	{
		MoveSpeed += MoveSpeed * AccelerationSpeed;
		AccelerationSpeed *= 0.96f;
		MovePositionUp(MoveSpeed, DeltaTime);
	}

	void AccelerateToHeight(float DeltaTime)
	{
		MoveSpeed += MoveSpeed * AccelerationSpeed;
		AccelerationSpeed *= 0.96f;

		if (CurrentPosition.Z < MaxHeight)
			MovePositionUp(MoveSpeed, DeltaTime);
		else
		{
			CurrentPosition.Z = MaxHeight;
        	SetWidgetWorldPosition(CurrentPosition);
		}
	}

	void ConstantIndefinite(float DeltaTime)
	{
		MovePositionUp(MoveSpeed, DeltaTime);
	}

	void ConstantToHeight(float DeltaTime)
	{
		if (CurrentPosition.Z < MaxHeight)
			MovePositionUp(MoveSpeed, DeltaTime);
		else
		{
			CurrentPosition.Z = MaxHeight;
        	SetWidgetWorldPosition(CurrentPosition);
		}
	}

	void DeccelerateIndefinite(float DeltaTime)
	{
		MoveSpeed -= MoveSpeed * AccelerationSpeed;
		AccelerationSpeed *= 0.96f;
		MovePositionUp(MoveSpeed, DeltaTime);
	}

	void DeccelerateToHeight(float DeltaTime)
	{
		MoveSpeed -= MoveSpeed * AccelerationSpeed;
		AccelerationSpeed *= 0.97f;

		if (CurrentPosition.Z < MaxHeight)
			MovePositionUp(MoveSpeed, DeltaTime);
		else
		{
			CurrentPosition.Z = MaxHeight;
        	SetWidgetWorldPosition(CurrentPosition);
		}
	}

	void MovePositionUp(float Value, float DeltaTime)
	{
		CurrentPosition.Z += Value * DeltaTime;
        SetWidgetWorldPosition(CurrentPosition);
	}

	void Bounciness(float DeltaTime)
	{
		if (CurrentBounce == 1)
		{
			TargetXScale = 1 + MaxTargetScale;
			TargetYScale = 1 + MaxTargetScale;
		}
		else if (CurrentBounce > 1 && CurrentBounce < MaxBounce)
		{
			if (bBouncePositive)
			{
				TargetXScale = 1 + MaxTargetScale / CurrentBounce / (CurrentBounce * 0.75f); 
				TargetYScale = 1 + MaxTargetScale / CurrentBounce / (CurrentBounce * 0.75f);
			}
			else
			{
				TargetXScale = 1 - MaxTargetScale / (CurrentBounce * NegativeDirectionMultiplier); 
				TargetYScale = 1 - MaxTargetScale / (CurrentBounce * NegativeDirectionMultiplier);				
			}
		}
		else
		{
			TargetXScale = 1.f; 
			TargetYScale = 1.f;			
		}

		float XDiff = FMath::Abs(XScale - TargetXScale);
		float YDiff = FMath::Abs(YScale - TargetYScale);

		if (XDiff < 0.1f && YDiff < 0.1f)
		{
			CurrentBounce++;
			bBouncePositive = !bBouncePositive;
		}
		
		XScale = FMath::FInterpTo(XScale, TargetXScale, DeltaTime, InterpSpeed);
		YScale = FMath::FInterpTo(YScale, TargetYScale, DeltaTime, InterpSpeed);

		SetScale(XScale, YScale);

		InterpSpeed *= InterpMultiplier;
	}	
};