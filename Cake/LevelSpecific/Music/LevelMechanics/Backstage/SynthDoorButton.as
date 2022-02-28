import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoor;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PulseEqualizerManager;

class ASynthDoorButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrameMeshRoot;

	UPROPERTY(DefaultComponent, Attach = FrameMeshRoot)
	USceneComponent ButtonMeshRoot;

	UPROPERTY(DefaultComponent, Attach = FrameMeshRoot)
	UStaticMeshComponent ButtonFrameMesh;

	UPROPERTY(DefaultComponent, Attach = ButtonMeshRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY()
	APulseEqualizerManager EQManager;

	UPROPERTY()
	ASynthDoor ConnectedSynthDoor;

	UPROPERTY()
	FHazeTimeLike PressButtonTimeline;

	bool bDoorHasOpened = false;
	bool bCanPressButton = false;

	float TargetProgress = 0.f;
	float CurrentProgress = 0.f;
	int TotalButtonToPress = 0;

	FVector StartingLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, -70.f);

	FVector LitColor = FVector(10.f, 0.f, 0.f);
	FVector UnlitColor = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");
		PressButtonTimeline.BindUpdate(this, n"PressButtonTimelineUpdate");
		ConnectedSynthDoor.SynthPuzzleSolved.AddUFunction(this, n"SynthPuzzleSolved");
	}

	void InitTotalButtonToPress(int ButtonsToPress)
	{
		TotalButtonToPress += ButtonsToPress;
	}

	void UpdateButtonProgress(int ProgressChange)
	{
		TargetProgress += ProgressChange;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void SynthPuzzleSolved(bool bSolved)
	{
		SetButtonEnabled(bSolved);		
	}

	void SetButtonEnabled(bool bEnabled)
	{
		if (bDoorHasOpened)
			return;
		
		if (bEnabled)
		{
			bCanPressButton = true;
			ButtonMesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", LitColor);
		} else
		{
			ButtonMesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", UnlitColor);
			bCanPressButton = false;
		}
	}	

	UFUNCTION()
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {
        if (!bCanPressButton)
			return;
		
		if (bDoorHasOpened)
			return;

		bDoorHasOpened = true;

		PressButtonTimeline.PlayFromStart();
		ConnectedSynthDoor.OpenDoor();
		EQManager.SetPulseEqualizerActive(true);
    }

	UFUNCTION()
	void PressButtonTimelineUpdate(float CurrentValue)
	{
		ButtonMeshRoot.SetRelativeLocation(FVector(FMath::Lerp(StartingLoc, TargetLoc, CurrentValue)));	
	}
}