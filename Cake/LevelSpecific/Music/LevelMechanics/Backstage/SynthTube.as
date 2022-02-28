import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachine;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PulseEqualizerManager;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorButton;

event void FCableSuccessEvent();

class ASynthTube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ESynthDoorMeterType SynthType;

	UPROPERTY()
	APulseEqualizerManager PulseEqualizerManager;

	UPROPERTY()
	ADrumMachine ConnectedMachine;

	UPROPERTY()
	ASynthDoorButton SynthDoorButton;
	
	UPROPERTY()
	FLinearColor TubeColor;

	UPROPERTY()
	FCableSuccessEvent CableSuccessEvent;

	int ButtonPressedGoal = 0; 
	int LastButtonPressed = 0;
	int CurrentButtonsPressed = 0;

	float CurrentMatOffset = 0.f;
	float TargetMatOffset = 0.f;
	float CurrentBlobSize = 0.f;
	float TargetBlobSize = 0.6f;
	float CurrentFlow = 0.f;
	float TargetFlow = 0.f;

	bool bHasPostedSucessEvent = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch (SynthType)
		{
			case ESynthDoorMeterType::Drum:
				ButtonPressedGoal = PulseEqualizerManager.DrumButtonPressGoal;
				break;

			case ESynthDoorMeterType::Synth:
				ButtonPressedGoal = PulseEqualizerManager.SynthButtonPressGoal;
				break;

			case ESynthDoorMeterType::Bass:
				ButtonPressedGoal = PulseEqualizerManager.BassButtonPressGoal;
				break;
		}

		ConnectedMachine.OnBeat.AddUFunction(this, n"OnBeat");
		ConnectedMachine.OnButtonToggled.AddUFunction(this, n"OnButtonToggled");
		Mesh.SetColorParameterValueOnMaterialIndex(0, n"Color", TubeColor);
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"VertexOffsetDistance", 50.f);
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Glow", 10.f);
		//SynthDoorButton.InitTotalButtonToPress(ButtonPressedGoal);
	}

	UFUNCTION()
	void OnBeat(ADrumMachine Machine, int ColumnIndex, int ColumnPressedButtons)
	{
		if (ColumnPressedButtons == 0)
			return;
		
		CurrentBlobSize = 1.f;

		if (CurrentButtonsPressed >= ButtonPressedGoal)
			CurrentFlow = 0.25f;
	}

	UFUNCTION()
	void OnButtonToggled(ADrumMachine Machine, int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		CurrentButtonsPressed = TotalPressedButtons;
		float TotalPressed = TotalPressedButtons;
		float ButtonGoal = ButtonPressedGoal;
		TargetMatOffset = TotalPressed / ButtonGoal;
		TargetMatOffset = FMath::Min(TargetMatOffset, 1.f);

		if (CurrentButtonsPressed >= ButtonPressedGoal && !bHasPostedSucessEvent)
		{
			bHasPostedSucessEvent = true;
			CableSuccessEvent.Broadcast();
		}
		
		// if (CurrentButtonsPressed > ButtonPressedGoal)
		// 	SynthDoorButton.UpdateButtonProgress(0);
		// else
		// 	SynthDoorButton.UpdateButtonProgress(CurrentButtonsPressed - LastButtonPressed);
		
		LastButtonPressed = CurrentButtonsPressed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentBlobSize = FMath::FInterpTo(CurrentBlobSize, TargetBlobSize, DeltaTime, 3.f);
		CurrentMatOffset = FMath::FInterpTo(CurrentMatOffset, TargetMatOffset, DeltaTime, 3.f);
		CurrentFlow = FMath::FInterpTo(CurrentFlow, TargetFlow, DeltaTime, 3.f);
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Blob", CurrentBlobSize);
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Offest", CurrentMatOffset);
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Flow", CurrentFlow);
	}
}