import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarDeviceWheel;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

event void FOnTugOfWarCompletedEventSignature(bool DidMayWin);
event void FOnTugOfWarStateChangeEventSignature(int State);
event void FOnTugOfWarMoveStartedEventSignature();
event void FOnTugOfWarMoveCompletedEventSignature();

//TODO:
//Fix Gamestart / Sequence / Won on network.

//
class UTugOfWarManagerComponent : UActorComponent
{
	//Current Progress of interaction (-InteractionSteps To InteractionSteps)
	int CurrentStep = 0;
	//Number Of Steps Per Player Side
	UPROPERTY(Category = "Settings|Manager")
	int InteractionSteps = 2;
	//Value to reach prior to state change
	UPROPERTY(Category = "Settings|Manager")
	float AmountPerStep = 10.0f;

	//Change in Progress per frame
	float MashDelta = 0.0f;
	//Current Progress in State Between -AmountPerStep and + AmountPerStep.
	float StepProgress = 0.0f;
	//Current Player1 ButtonMash Value
	float Player1MashRate = 0.f;
	//Current Player2 ButtonMash Value
	float Player2MashRate = 0.f;

	//Audio Specifics
	/*
		Start events are fired in PlayTimelike(),
		Stop events are fired in OnTimeLikeFinished()
		For Gameplay State of how close players are to edge check CurrentStep above.
	*/

	//Reference AK Components on main actor to post events from here, Set on beginplay in TugOfWarActor.
	UHazeAkComponent HazeAkCompCogsLeftSide;
	UHazeAkComponent HazeAkCompCogsRightSide;
	UHazeAkComponent HazeAkCompRope;

	//Total ButtonMashPerFrame (Will update when Solor or both players interacting)
	float CurrentTotalButtonMashing = 0.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartRopeAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent StopRopeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartCogsLeftSideAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartCogsRightSideAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent StopCogsLeftSideAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent StopCogsRightSideAudioEvent;

	UPROPERTY(Category = "Settings|Manager")
	float StepDistance = 133.f;
	UPROPERTY(Category = "Settings|Manager")
	float TilingPerStep = 1.f;

	float TilingTarget = 0.f;
	float CurrentTiling = 0.f;

	UPROPERTY(Category = "Settings|Manager")
	float RotationSpeed = 3.f;
	
	int DirSign = 0;
	int TargetStep = 0;

	float CurrentPositionP1 = 0.f;
	float CurrentPositionP2 = 0.f;
	float TargetPositionP1 = 0.f;
	float TargetPositionP2 = 0.f;

	float DefaultPositionP1;
	float DefaultPositionP2;

	float TargetStepProgress = 0.f;

	bool bLeftPlayerMoveComplete = false;
	bool bRightPlayerMoveComplete = false;

	bool bInteractionStarted = false;
	bool bInteractionCompleted = false;
	bool bMoveInProgress = false;
	bool bShouldMoveCharacters = true;

	FOnTugOfWarCompletedEventSignature OnCompleted;
	FOnTugOfWarStateChangeEventSignature OnStateChange;
	FOnTugOfWarMoveStartedEventSignature OnMoveStarted;
	FOnTugOfWarMoveCompletedEventSignature OnMoveCompleted;

	AHazePlayerCharacter LeftPlayer;
	AHazePlayerCharacter RightPlayer;

	AHazePlayerCharacter PlayerWonMove;

	USceneComponent LeftAttach;
	USceneComponent RightAttach;
	USceneComponent LeftButtonMashPosition;
	USceneComponent RightButtonMashPosition;

	UButtonMashDefaultHandle Player1Handle;
	UButtonMashDefaultHandle Player2Handle;
	
	UPROPERTY()
	FHazeTimeLike StepTimeLike;
	default StepTimeLike.Duration = 1.f;

	FVector LeftAttachLocation = FVector::ZeroVector;
	FVector RightAttachLocation = FVector::ZeroVector;

	float DeltaSeconds;

	TArray<UMaterialInstanceDynamic> RopeMaterials;
	UPROPERTY(Category = "Setup")
	TArray<ATugOfWarDeviceWheel> RotationWheels;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StepTimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		StepTimeLike.BindFinished(this, n"OnTimeLikeFinished");
	}

	void InitializeVariables()
	{
		DefaultPositionP1 = LeftAttach.RelativeLocation.X;
		DefaultPositionP2 = RightAttach.RelativeLocation.X;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DeltaSeconds = DeltaTime;

		if(!bMoveInProgress)
			CalculateMashDelta();
		else
		{
			//We are moving, clear buttonmash to prepare for new "round"
			Player1Handle.ResetButtonMash();
			Player2Handle.ResetButtonMash();
		}

		if(!bInteractionStarted)
		{
			//If only 1 player is interacting
			if((LeftPlayer != nullptr || RightPlayer != nullptr) && MashDelta != 0)
				HandleSingleButtonMash(DeltaTime);
			return;
		}

		//For Network Remote Side, interpolate Rope / Characters towards target and rotate wheels.
		if(!HasControl() && !bInteractionCompleted)
		{
			if(bShouldMoveCharacters)
			{
				float NewLocationP1 = FMath::FInterpConstantTo(CurrentPositionP1, TargetPositionP1, DeltaTime, 200.f);
				float NewLocationP2 = FMath::FInterpConstantTo(CurrentPositionP2, TargetPositionP2, DeltaTime, 200.f);
				LeftAttach.SetRelativeLocation(FVector(NewLocationP1, LeftAttach.RelativeLocation.Y, LeftAttach.RelativeLocation.Z));
				RightAttach.SetRelativeLocation(FVector(NewLocationP2, RightAttach.RelativeLocation.Y, RightAttach.RelativeLocation.Z));

				CurrentPositionP1 = LeftAttach.RelativeLocation.X;
				CurrentPositionP2 = RightAttach.RelativeLocation.X;
			}

			//Ropes move towards target at a constant speed
			float NewTiling = FMath::FInterpConstantTo(CurrentTiling, TilingTarget, DeltaTime, 2.5f);
			SetArrayTilingParam(NewTiling);

			SetArrayWheelRotation();

			if(CurrentTiling != NewTiling)
				CurrentTiling = RopeMaterials[0].GetScalarParameterValue(n"CustomTime");
		}

		if(bInteractionCompleted)
			return;

		if(HasControl())
		{
			VerifyStepProgress();
		}
		else
		{
			StepProgress = FMath::FInterpConstantTo(StepProgress, TargetStepProgress, DeltaTime, 10.f);
		}
	}

	void ResetMashRate()
	{
		MashDelta = 0.f;
		Player1MashRate = 0.f;
		Player2MashRate = 0.f;
	}

	//Calculate Delta and total buttonmash.
	void CalculateMashDelta()
	{
		MashDelta = Player1MashRate	 - Player2MashRate;

		CurrentTotalButtonMashing = Player1MashRate + Player2MashRate;

		HazeAkCompCogsLeftSide.SetRTPCValue("Rtpc_World_SideContent_Tree_MiniGame_TugOfWar_MashRate", CurrentTotalButtonMashing);
		HazeAkCompCogsRightSide.SetRTPCValue("Rtpc_World_SideContent_Tree_MiniGame_TugOfWar_MashRate", CurrentTotalButtonMashing);
		HazeAkCompRope.SetRTPCValue("Rtpc_World_SideContent_Tree_MiniGame_TugOfWar_MashRate", CurrentTotalButtonMashing);
	}

	void VerifyStepProgress()
	{
		StepProgress += MashDelta;
		TargetStep = CurrentStep;

		if(StepProgress >= AmountPerStep)
		{
			TargetStep++;
			StepProgress = 0;
			if(!VerifyCompletion())
			{
				PrepareStepMove();
				OnMoveStarted.Broadcast();
				MashDelta = 0;
				Player1MashRate = 0;
				Player2MashRate = 0;

				PlayTimeLike();
				OnStateChange.Broadcast(TargetStep);
			}
		}
		else if(StepProgress <= -AmountPerStep)
		{
			TargetStep--;
			StepProgress = 0;
			if(!VerifyCompletion())
			{
				PrepareStepMove();
				OnMoveStarted.Broadcast();
				MashDelta = 0;
				Player1MashRate = 0;
				Player2MashRate = 0;

				PlayTimeLike();
				OnStateChange.Broadcast(TargetStep);
			}
		}

		if(VerifyNetSendRate(DeltaSeconds))
			NetSetStepProgress(StepProgress);
	}

	void StartPlayer1Handle()
	{
		Player1Handle = StartButtonMashDefaultAttachToComponent(LeftPlayer, LeftButtonMashPosition, NAME_None, FVector::ZeroVector);

		if(!Player1Handle.bIsExclusive)
			Player1Handle.bIsExclusive = true;

		if(!Player1Handle.bSyncOverNetwork && Network::IsNetworked())
			Player1Handle.bSyncOverNetwork = true;

	}

	void StartPlayer2Handle()
	{
		Player2Handle = StartButtonMashDefaultAttachToComponent(RightPlayer, RightButtonMashPosition, NAME_None, FVector::ZeroVector);

		if(!Player2Handle.bIsExclusive)
			Player2Handle.bIsExclusive = true;

		if(!Player2Handle.bSyncOverNetwork && Network::IsNetworked())
			Player2Handle.bSyncOverNetwork = true;
	}

	void StopPlayer1Handle()
	{
		if(Player1Handle != nullptr)
			Player1Handle.StopButtonMash();
	}

	void StopPlayer2Handle()
	{
		if(Player2Handle != nullptr)
			Player2Handle.StopButtonMash();
	}

	bool VerifyCompletion()
	{
		if(TargetStep >= InteractionSteps + 1)
		{
			bInteractionCompleted = true;
			OnCompleted.Broadcast(true);
			NetSetCompleted(true);
			return true;
		}
		else if(TargetStep <= -InteractionSteps - 1)
		{
			bInteractionCompleted = true;
			OnCompleted.Broadcast(false);
			NetSetCompleted(true);
			return true;
		}
		return false;
	}

	//Step completed, prepare Control/remote sides
	void PrepareStepMove()
	{
		NetSetIsMoving(true);
		bLeftPlayerMoveComplete = false;
		bRightPlayerMoveComplete = false;

		if(bShouldMoveCharacters)
		{
			/* *AUDIO* Started Move With Characters */

			CurrentPositionP1 = LeftAttach.RelativeLocation.X;
			CurrentPositionP2 = RightAttach.RelativeLocation.X;

			DirSign = CurrentStep - TargetStep;
			float Distance = DirSign * StepDistance;

			TargetPositionP1 = CurrentPositionP1 + Distance;
			TargetPositionP2 = CurrentPositionP2 + (Distance * -1.f);

		}
		else
		{
			/* Started Move Without Characters */

			
		}

		TilingTarget = CurrentTiling + (TilingPerStep * DirSign);

		NetChangeState(TargetStep);
		NetSetTargets(TargetPositionP1, TargetPositionP2, TilingTarget, DirSign);
	}

	//Called from Sequence to Move Wheels/rope in accordance to sequence
	UFUNCTION(BlueprintCallable)
	void OnMayWin()
	{
		NetSetShouldMoveCharacters(false);
		DirSign = -3.f;
		NetSetVisualsDirectionSign(DirSign);
		PlayTimelikeNoTranslation();
	}

	UFUNCTION(BlueprintCallable)
	void OnCodyWin()
	{
		NetSetShouldMoveCharacters(false);
		DirSign = 2.f;
		NetSetVisualsDirectionSign(DirSign);
		PlayTimelikeNoTranslation();
	}

	//Start Timelike
	UFUNCTION()
	void PlayTimeLike()
	{
		StepTimeLike.PlayFromStart();

		/* Fire Rope/Cog/etc End events */
		if(HazeAkCompCogsRightSide != nullptr)
		{
			HazeAkCompCogsRightSide.HazePostEvent(StartCogsRightSideAudioEvent);
		}

		if(HazeAkCompCogsLeftSide != nullptr)
		{
			HazeAkCompCogsLeftSide.HazePostEvent(StartCogsLeftSideAudioEvent);
		}

		if(HazeAkCompRope != nullptr)
		{
			HazeAkCompRope.HazePostEvent(StartRopeAudioEvent);
		}
	}

	//Update Timelike to move rope/wheels/Players on control side
	UFUNCTION()
	void OnTimeLikeUpdate(float Value)
	{
		if(bShouldMoveCharacters)
		{
			float NewLocationP1 = FMath::Lerp(CurrentPositionP1, TargetPositionP1, Value);
			float NewLocationP2 = FMath::Lerp(CurrentPositionP2, TargetPositionP2, Value);
			LeftAttach.SetRelativeLocation(FVector(NewLocationP1, LeftAttach.RelativeLocation.Y, LeftAttach.RelativeLocation.Z));
			RightAttach.SetRelativeLocation(FVector(NewLocationP2, RightAttach.RelativeLocation.Y, RightAttach.RelativeLocation.Z));
		}

		float NewTiling = FMath::Lerp(CurrentTiling, TilingTarget, Value);

		SetArrayTilingParam(NewTiling);
		SetArrayWheelRotation();
	}

	//Move Cogs/rope but not players (used for LevelSequence)
	void PlayTimelikeNoTranslation()
	{
		TilingTarget = CurrentTiling + (TilingPerStep * DirSign);
		PlayTimeLike();
		NetSetTargets(TargetPositionP1, TargetPositionP2, TilingTarget, DirSign);
	}

	//Finish timelike move, set Remote direction for lerping to 0;
	UFUNCTION()
	void OnTimeLikeFinished()
	{
		CurrentTiling = RopeMaterials[0].GetScalarParameterValue(n"CustomTime");
		
		NetSetIsMoving(false);

		if(bShouldMoveCharacters)
			OnMoveCompleted.Broadcast();

		NetSetVisualsDirectionSign(0);
	}

	void SetArrayTilingParam(float Tiling)
	{
		for(int i = 0; i < RopeMaterials.Num(); i++)
		{
			RopeMaterials[i].SetScalarParameterValue(n"CustomTime", Tiling);
		}
	}

	void SetArrayWheelRotation()
	{	
		for(int i = 0; i < RotationWheels.Num(); i++)
		{
			RotationWheels[i].RotationRoot.AddLocalRotation(FRotator(((RotationWheels[i].RotationSpeed * DirSign) * RotationSpeed) * DeltaSeconds,0,0));
		}
	}

	void InterpArrayWheelRotation()
	{
		for (int i = 0; i < RotationWheels.Num(); i++)
		{
			USceneComponent WheelRoot = RotationWheels[i].RotationRoot;
			float TargetRotation = (RotationWheels[i].RotationSpeed * 100 * FMath::Abs(MashDelta) * DirSign) * DeltaSeconds;

			WheelRoot.AddLocalRotation(FRotator(TargetRotation, 0, 0));
		}
	}

	UFUNCTION()
	void ResetCompletion()
	{
		bInteractionStarted = false;
		bInteractionCompleted = false;
		bShouldMoveCharacters = true;
		StepProgress = 0.f;
		CurrentStep = 0;
		TargetStep = 0;

		LeftAttach.SetRelativeLocation(FVector(DefaultPositionP1, LeftAttach.RelativeLocation.Y, LeftAttach.RelativeLocation.Z));
		RightAttach.SetRelativeLocation(FVector(DefaultPositionP2, RightAttach.RelativeLocation.Y, RightAttach.RelativeLocation.Z));

		TargetPositionP1 = DefaultPositionP1;
		TargetPositionP2 = DefaultPositionP2;
		CurrentPositionP1 = DefaultPositionP1;
		CurrentPositionP2 = DefaultPositionP2;
		DirSign = 0;
	}

	//Single player interacting
	UFUNCTION()
	void HandleSingleButtonMash(float DeltaTime)
	{
		float Max = 0.12f;
		float Multiplier = 400;
		float CurrentRate = FMath::Clamp(MashDelta, -Max, Max);
		DirSign = FMath::Sign(MashDelta);

		if(DirSign != 0)
			DirSign *= -1;
		
		float Step = Max / TilingPerStep;
		float TilingToSet = (CurrentRate * Step * Multiplier) * DeltaTime;
		TilingToSet *= -1;
		TilingToSet += CurrentTiling;

		SetArrayTilingParam(TilingToSet);
		InterpArrayWheelRotation();
		CurrentTiling = TilingToSet;
		TilingTarget = CurrentTiling;
	}

//Netfunctions

	float NetworkRate = 0.075f;
	float NetworkNewTime = 0.f;

	bool VerifyNetSendRate(float DeltaTime)
	{
		if(NetworkNewTime <= System::GameTimeInSeconds)
		{
			NetworkNewTime = System::GameTimeInSeconds + NetworkRate;

			return true;
		}
		else
			return false;
	}

	UFUNCTION(NetFunction)
	void NetChangeState(int StateChange)
	{
		if (StateChange > CurrentStep)
			PlayerWonMove = Game::May;
		else
			PlayerWonMove = Game::Cody;
		
		Print("PlayerWonMove: " + PlayerWonMove);

		CurrentStep = StateChange;
	}

	UFUNCTION(NetFunction)
	void NetSetShouldMoveCharacters(bool ShouldMove)
	{
		bShouldMoveCharacters = ShouldMove;
	}

	UFUNCTION(NetFunction)
	void NetSetVisualsDirectionSign(float Direction)
	{
		DirSign = Direction;
	}

	UFUNCTION(NetFunction)
	void NetSetStepProgress(float Value)
	{
		if(!HasControl())
			TargetStepProgress = Value;
	}

	UFUNCTION(NetFunction)
	void NetSetCompleted(bool Completed)
	{
		bInteractionCompleted = Completed;
	}

	UFUNCTION(NetFunction)
	void NetSetIsMoving(bool IsMoving)
	{
		if(IsMoving)
			bMoveInProgress = true;
		else
			bMoveInProgress = false;
	}

	UFUNCTION(NetFunction)
	void NetSetTargets(float TargetPosP1, float TargetPosP2, float Tiling, float Direction)
	{
		if(bShouldMoveCharacters)
		{
			TargetPositionP1 = TargetPosP1;
			TargetPositionP2 = TargetPosP2;
		}
		TilingTarget = Tiling;
		DirSign = Direction;
	}

	UFUNCTION(NetFunction)
	void ControlCompleteMove()
	{
		bLeftPlayerMoveComplete = true;
		bRightPlayerMoveComplete = true;
	}
}