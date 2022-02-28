event void FDrumMachineButtonComponentToggled(UDrumMachineButtonComponent Button);

class UDrumMachineButtonComponent : UStaticMeshComponent
{
    //default StaticMesh = Asset("/Engine/BasicShapes/Cube.Cube");
    default RelativeScale3D = FVector(1.f, 1.f, 1.f);

	UPROPERTY()
	UMaterialInterface ButtonPressedMaterial;
	
	UPROPERTY()
	UMaterialInterface ButtonReleasedMaterial;

	UPROPERTY()
	UAkAudioEvent Sound;

	UPROPERTY()
	UCurveFloat ButtonMoveCurve;

	FVector2D LocalMin;
	FVector2D LocalMax;

	FVector PressedOriginalVectorValue;
	FVector ReleasedOriginalVectorValue;

	UPROPERTY(BlueprintReadOnly)
	int ColumnIndex = 0;

	UPROPERTY(BlueprintReadOnly)
	int RowIndex = 0;

	UPROPERTY()
	FVector ButtonDetectionPadding = FVector(50.f, 50.f, 0.f);

	UPROPERTY()
	float ToggleCooldown = 0.5f;
	float ToggleTime = -BIG_NUMBER;

	UPROPERTY(BlueprintReadOnly)
	bool bButtonPressed = false;

	UPROPERTY()
	FHazeTimeLike MoveButtonTimeline;
	default MoveButtonTimeline.Duration = 0.2f;	

	FDrumMachineButtonComponentToggled OnToggled;

	FVector StartingLocation = FVector::ZeroVector;
	FVector TargetLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bButtonPressed)
			PressButton();

		// Setting Original values for VectorParameter Emmisive Tint on Pressed and Released materal
		UMaterialInstance PressedOriginalMat = Cast<UMaterialInstance>(ButtonPressedMaterial);
		UMaterialInstance ReleasedOriginalMat = Cast<UMaterialInstance>(ButtonReleasedMaterial);

		MoveButtonTimeline.BindUpdate(this, n"MoveButtonTimelineUpdate");

		StartingLocation = RelativeLocation;
		TargetLocation = StartingLocation - FVector(0.f, 0.f, 45.f);

		auto PressedVectorValueArray = PressedOriginalMat.VectorParameterValues;
		auto ReleasedVectorValueArray = ReleasedOriginalMat.VectorParameterValues;

		for (FVectorParameterValue Value : PressedVectorValueArray)
		{
			if (Value.ParameterInfo.Name == n"Emissive Tint")
				PressedOriginalVectorValue = FVector(Value.ParameterValue.R, Value.ParameterValue.G, Value.ParameterValue.B);
		}

		for (FVectorParameterValue Value : ReleasedVectorValueArray)
		{
			if (Value.ParameterInfo.Name == n"Emissive Tint")
				ReleasedOriginalVectorValue = FVector(Value.ParameterValue.R, Value.ParameterValue.G, Value.ParameterValue.B);;
		}
	}

	FVector GetDetectionSize()
	{
		return RelativeScale3D * 200.f + ButtonDetectionPadding;
	} 

	void OnGroundPounded(AHazePlayerCharacter GroundPounder)
	{
		// Groundpounder controlling side decides if button should be turned on or off, don't toggle!
		if (!GroundPounder.HasControl())
			return;

		if (Time::GetGameTimeSince(ToggleTime) < ToggleCooldown)
			return;
			
		if (bButtonPressed)
			NetReleaseButton();
		else
			NetPressButton();
	}

	UFUNCTION(NetFunction)
	void NetPressButton()
	{
		PressButton();
	}

	UFUNCTION(NetFunction)
	void NetReleaseButton()
	{
		ReleaseButton();
	}

	void PressButton()
	{
		if (!bButtonPressed)
		{
			bButtonPressed = true;
			SetMaterial(0, ButtonPressedMaterial);
			OnToggled.Broadcast(this);
		}

		MoveButtonTimeline.PlayFromStart();
	}

	void ReleaseButton()
	{
		if (bButtonPressed)
		{
			bButtonPressed = false;
			SetMaterial(0, ButtonReleasedMaterial);
			OnToggled.Broadcast(this);
		}
		
		MoveButtonTimeline.PlayFromStart();
	}

	void Beat()
	{
		if (bButtonPressed)
		{
			//AkGameplay::PostEventAtLocation(Sound, WorldLocation, WorldRotation, "DrumMachineButton");
			UHazeAkComponent::HazePostEventFireForget(Sound, GetWorldTransform());
			SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", PressedOriginalVectorValue * 10);	
		} else
		{
			SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", ReleasedOriginalVectorValue * 10);	
		}

	}

	void BeatOver()
	{
		if (bButtonPressed)	
			SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", PressedOriginalVectorValue);	
		else
			SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", ReleasedOriginalVectorValue);
	}

	UFUNCTION()
	void MoveButtonTimelineUpdate(float CurrentValue)
	{
		RelativeLocation = FMath::Lerp(StartingLocation, TargetLocation, CurrentValue);
	}
}