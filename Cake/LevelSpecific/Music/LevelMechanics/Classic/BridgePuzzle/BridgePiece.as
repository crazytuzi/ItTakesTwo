import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.AudioStatics;
class ABridgePiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BridgePieceMesh;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UBoxComponent Trigger;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UArrowComponent LaunchArrowDirection;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothFloatSyncRotation;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent AccleratedFloatSync;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMoveEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMoveEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FullyDownEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FullyUpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MegaTrumpetStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MegaTrumpetStopEvent;

	float StartRotation = 0;
	float TargetPitchValue = 0;
	float CurrentPitchValue;
	float LerpToTargetValue;
	float SongOfLifeTargetValue = 43.f;
	FHazeAcceleratedFloat AcceleratedFloat;

	float PushBackMultiplier = 8500;
	float LocalNewRotationValue;
	float LocalRotationValue;

	bool bSongOfLifeActive = false;
	bool bAllowReactivation = true;
	bool bPowerfulSongActive = false;
	float RotateTargetValue = 0;
	float StiffnessValue = 9;
	float DampValue = 0.25f;
	bool bPuzzleCompelete = false;
	float LastRoll;

	bool bWasFullyUp = false;
	bool bWasFullyDown = false;

	bool bPreAllowImpact = true;


	UPROPERTY()
	bool bPrint = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::May);
		AccleratedFloatSync.OverrideControlSide(Game::GetMay());
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPuzzleCompelete)
			return;

		// We know it will always be may in control. See BeginPlay
		if(HasControl())
		{
			TickMovement(DeltaSeconds);
			SmoothFloatSyncRotation.Value = BridgePieceMesh.GetRelativeRotation();
			AccleratedFloatSync.Value = AcceleratedFloat.Value;
		}
		else
		{	
			AcceleratedFloat.Value = AccleratedFloatSync.Value;
			// If don't do this on remote, movement sound etc won't be posted/stopped.
			TickMovement(DeltaSeconds);
		}
	}

	UFUNCTION()
	void TickMovement(float DeltaSeconds)
	{
		float CurrentRoll = SmoothFloatSyncRotation.Value.Roll;
		
		float RollNorm = HazeAudio::NormalizeRTPC01(FMath::Abs(CurrentRoll - LastRoll), 0.f , 4.f);
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Classic_Platforms_TrumpetBridge_Rotation", RollNorm);
		//Print("Bridge Rot: " + RollNorm, 0.f);

		LastRoll = CurrentRoll;
		
		// PrintToScreen("AcceleratedFloat " + AcceleratedFloat.Value);
		// PrintToScreen("bPowerfulSongActive " + bPowerfulSongActive);
		// PrintToScreen("RollNorm " + RollNorm);
		if(bPowerfulSongActive)
		{
			StiffnessValue = 9;
			DampValue = 0.25;
			if (HasControl())
				AcceleratedFloat.SpringTo(RotateTargetValue, 15, 0.475f, DeltaSeconds);
			TargetPitchValue = AcceleratedFloat.Value;
			BridgePieceMesh.SetRelativeRotation(FRotator(0, 0, TargetPitchValue));

			if(AcceleratedFloat.Value >= RotateTargetValue && !bWasFullyUp)
			{
				HazeAkComp.HazePostEvent(FullyUpEvent);
				HazeAkComp.HazePostEvent(StopMoveEvent);
				bWasFullyUp = true;
				bWasFullyDown = false;
				Print("FullyUp and STOP", 1.f);
			}
		}
		else if(!bPowerfulSongActive)
		{

			StiffnessValue = 10;
			DampValue = 0.35;
			if(AcceleratedFloat.Value >= 180)
			{
				AcceleratedFloat.Value -= 360;
				RotateTargetValue = 0;
			}

			if (HasControl())
				AcceleratedFloat.SpringTo(RotateTargetValue, StiffnessValue, DampValue, DeltaSeconds);
			TargetPitchValue = AcceleratedFloat.Value;
			BridgePieceMesh.SetRelativeRotation(FRotator(0, 0, TargetPitchValue));

			if(AcceleratedFloat.Value <= RotateTargetValue && !bWasFullyDown)
			{
				HazeAkComp.HazePostEvent(FullyDownEvent);
				HazeAkComp.HazePostEvent(StopMoveEvent);
				bWasFullyDown = true;
				bWasFullyUp = false;
				Print("FullyDown and STOP", 1.f);
			}
		} 
	}


	UFUNCTION()
	void PowerfulSongActivated()
	{
		if(!bAllowReactivation)
			return;
		if(!bPreAllowImpact)
			return;

		bPreAllowImpact = false;
		bPowerfulSongActive = true;
		RotateTargetValue = 90;

		HazeAkComp.HazePostEvent(StartMoveEvent);
		HazeAkComp.HazePostEvent(MegaTrumpetStartEvent);

		System::SetTimer(this, n"AllowPreImpact", 2.0f, false);	
		System::SetTimer(this, n"PowerfulSongTimer", 4.65f, false);		
	}

	UFUNCTION()
	void AllowPreImpact()
	{
		bPreAllowImpact = true;
	}	
	
	UFUNCTION()
	void PowerfulSongTimer()
	{
		if(!bAllowReactivation)
			return;

		RotateTargetValue = 0;
		bPowerfulSongActive = false;
		HazeAkComp.HazePostEvent(StartMoveEvent);
		HazeAkComp.HazePostEvent(MegaTrumpetStopEvent);
		//Print("Start", 1.f);
	}	


	UFUNCTION()
	void CompletePuzzle()
	{
		bAllowReactivation = false;
		bPowerfulSongActive = true;
		RotateTargetValue = 90;
		StiffnessValue = 9;
		DampValue = 0.25;
	}
	UFUNCTION()
	void CompletePuzzleInstantly()
	{
		bPuzzleCompelete = true;
		bAllowReactivation = false;
		BridgePieceMesh.SetRelativeRotation(FRotator(0, 0, 90));
	}
}

