import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingActor;

class UTVGamePlayScreenCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ATVHackingActor TVActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ColorSwapFailAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ColorSwapSuccessAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ScreenDistortionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopScreenDistortionAudioEvent;

	UPROPERTY(Category = "Setup")
	FVector2D Player1Start = FVector2D(-0.25f, -0.3f);
	UPROPERTY(Category = "Setup")
	FVector2D Player2Start = FVector2D(0.37f, 0.45f);

	FVector2D Player1Position = FVector2D::ZeroVector;
	FVector2D Player2Position = FVector2D::ZeroVector;

	//Timelike for reseting Player Position on cancel interact.
	UPROPERTY(Category = "Setup")
	FHazeTimeLike ResetTimeLikeP1;
	default ResetTimeLikeP1.Duration = 1.f;
	//Timelike for reseting Player Position on cancel interact.
	UPROPERTY(Category = "Setup")
	FHazeTimeLike ResetTimeLikeP2;
	default ResetTimeLikeP2.Duration = 1.f;
	//Timlike for increasing progress bar on completion.
	UPROPERTY(Category = "Setup")
	FHazeTimeLike ProgressTimeLike;
	default ProgressTimeLike.Duration = 0.5f;
	//Timelike for Distortion effect when both players are in position.
	UPROPERTY(Category = "Setup")
	FHazeTimeLike DistortionTimeLike;
	default DistortionTimeLike.Duration = 0.2f;
	//Timelike for Completed Level transition.
	UPROPERTY(Category = "Setup")
	FHazeTimeLike CompletionTimeLike;
	default CompletionTimeLike.Duration = 0.5f;

	UPROPERTY(Category = "Setup")
	ETVStateEnum CurrentLevel;

	UPROPERTY(Category = "Setup")
	ETVStateEnum Nextlevel;

	UPROPERTY(Category = "VO Settings")
	bool bHasVOEvent = false;

	UPROPERTY(Category = "VO Settings", meta = (EditCondition = "bHasVOEvent"))
	float VODelayFromStartingLevel = 2.f;

	UPROPERTY(Category = "Setup")
	bool bIsStartLevel = false;

	UPROPERTY(Category = "Setup")
	bool bIsFinalLevel = false;

	UPROPERTY(Category = "Setup")
	bool bMayLoopOnLeftSide = false;

	UPROPERTY(Category = "Setup")
	bool bCodyLoopOnLeftSide = false;

	UPROPERTY(Category = "Setup")
	bool bMayLoopOnUpperSide = false;

	UPROPERTY(Category = "Setup")
	bool bCodyLoopOnUpperSide = false;

	int MaterialIndexToUse = 1;

	float PlayerSpeed = 0.2;
	float CompletionTimePlayer1 = 0;
	float CompletionTimePlayer2 = 0;
	float CompletionHoldTime = 2.5f;
	float CompletionLeniency = 0.01f;
	float VOTimer = 0.f;
	float CurrentProgress = 0.f;
	float PositiveTargetRange = 0.f;
	float NegativeTargetRange = 0.f;

	bool bPlayer1Complete = false;
	bool bPlayer2Complete = false;
	bool bLevelCompleted = false;
	bool bPlayer1Aligned = false;
	bool bPlayer2Aligned = false;
	bool bPlayersAligned = false;
	bool bReversingCompletion = false;

	bool bHasVOPlayed = false;

	UPROPERTY(Category = "Settings")
	float LevelCompleteProgress = 0.f;

	UPROPERTY(Category = "Setup")
	FVector2D P1LoopingLimits = FVector2D::ZeroVector;

	UPROPERTY(Category = "Setup")
	FVector2D P2LoopingLimits = FVector2D::ZeroVector;

	FVector2D P1Position = FVector2D::ZeroVector;
	FVector2D P2Position = FVector2D::ZeroVector;

	FHazeAudioEventInstance ScreenDistortionEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TVActor = Cast<ATVHackingActor>(Owner);

		if(TVActor != nullptr)
			MaterialIndexToUse = TVActor.InteractiveMaterialIndex;

		ResetTimeLikeP1.BindUpdate(this, n"ResetPlayer1OnUpdate");
		ResetTimeLikeP2.BindUpdate(this, n"ResetPlayer2OnUpdate");
		ProgressTimeLike.BindUpdate(this, n"OnProgressUpdate");
		ProgressTimeLike.BindFinished(this, n"OnProgressFinished");
		DistortionTimeLike.BindUpdate(this, n"OnDistortionUpdate");
		DistortionTimeLike.BindFinished(this, n"OnDistortionFinished");
		CompletionTimeLike.BindUpdate(this, n"OnCompletionUpdate");
		CompletionTimeLike.BindFinished(this, n"OnCompletionFinished");

		PlayerSpeed = TVActor.ControlSpeed;
		CompletionHoldTime = TVActor.HoldRequiredTime;
		CompletionLeniency = TVActor.CompletionLeniency;

		PositiveTargetRange = 0 + CompletionLeniency;
		NegativeTargetRange = 0 - CompletionLeniency;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TVActor.TVState == CurrentLevel)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TVActor.TVState != CurrentLevel)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TVActor.Player1Position = Player1Start;
		TVActor.Player2Position = Player2Start;

		if(!bIsStartLevel)
		{
			CurrentProgress = TVActor.InteractionProgress;
			SetScalarParam(n"Hackedness", CurrentProgress);

			//Blend into level using reverse distortion timelike.
			CompletionTimeLike.ReverseFromEnd();
			bReversingCompletion = true;

			if(HasControl())
				TVActor.SwitchInputEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ResetState();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bLevelCompleted)
		{
			SetPosition();
			ValidateCompletion(DeltaTime);
		}
		ValidatePlayer1Playing();
		ValidatePlayer2Playing();

		ApplyForceFeedback();

		//VO Barks
		if(HasControl())
		{
			if(bHasVOEvent)
			{
				if(!bHasVOPlayed && IsActioning(n"Player1Playing") && IsActioning(n"Player2Playing"))
				{
					if(VOTimer >= VODelayFromStartingLevel)
					{
						if(CurrentLevel == ETVStateEnum::StartScreen)
							TVActor.TriggerStartScreenDialogue();
						else if(CurrentLevel == ETVStateEnum::Level2)
							TVActor.TriggerHackingDialogue();
							
						bHasVOPlayed = true;
					}
					else
					{
						VOTimer += DeltaTime;
					}
				}
				else
				{
					VOTimer = 0.f;
				}
			}
		}
	}

	FVector2D ClampPositions(FVector2D TargetPosition)
	{
		FVector2D ClampedTarget = TargetPosition;

		float Remainder = (TargetPosition.X - FMath::FloorToInt(TargetPosition.X));
		if(Remainder > 0.5f)
		{
			ClampedTarget.X = TargetPosition.X - FMath::CeilToInt(TargetPosition.X);
		}
		else
		{
			ClampedTarget.X = TargetPosition.X - FMath::FloorToInt(TargetPosition.X);
		}
		
		Remainder = (TargetPosition.Y - FMath::FloorToInt(TargetPosition.Y));
		if(Remainder > 0.5f)
		{
			ClampedTarget.Y = TargetPosition.Y - FMath::CeilToInt(TargetPosition.Y);
		}
		else
		{
			ClampedTarget.Y = TargetPosition.Y - FMath::FloorToInt(TargetPosition.Y);
		}

		return ClampedTarget;
	}

	void SetPosition()
	{
 		P1Position = ClampPositions(TVActor.Player1Position);
		P2Position = ClampPositions(TVActor.Player2Position);

		FLinearColor NewPositions = FLinearColor(P1Position.X, P1Position.Y, P2Position.X, P2Position.Y);
		SetPositionParam(n"PlayerPositions", NewPositions);
	}

	//Runs on tick to check if player is in completed range.
	void ValidateCompletion(float DeltaTime)
	{
		if(bLevelCompleted)
			return;

		if((P1Position.X > NegativeTargetRange && P1Position.X < PositiveTargetRange) && (P1Position.Y > NegativeTargetRange && P1Position.Y < PositiveTargetRange))
		{
			if(CompletionTimePlayer1 < CompletionHoldTime)
			{
				CompletionTimePlayer1 += DeltaTime;

				if(!bPlayer1Aligned)
				{
					bPlayer1Aligned = true;
					//Color is swapped to completed color player 1.
					TVActor.HazeAkComp.HazePostEvent(ColorSwapSuccessAudioEvent);
					SetScalarParam(n"PlayerOneAligned", 1);
				}
			}
			else if(!bPlayer1Complete && CompletionTimePlayer1 >= CompletionHoldTime)
			{
				bPlayer1Complete = true;
			}
		}
		else
		{
			CompletionTimePlayer1 = 0;
			bPlayer1Complete = false;

			if(bPlayer1Aligned)
			{
				bPlayer1Aligned = false;
				//Color is swapped to incomplete player 1.
				TVActor.HazeAkComp.HazePostEvent(ColorSwapFailAudioEvent);
				SetScalarParam(n"PlayerOneAligned", 0);
				if(TVActor.HazeAkComp.EventInstanceIsPlaying(ScreenDistortionEventInstance))
				{
					TVActor.HazeAkComp.HazePostEvent(StopScreenDistortionAudioEvent);
				}
			}
		}
		
		if((P2Position.X > 0 - CompletionLeniency && P2Position.X < 0 + CompletionLeniency) && (P2Position.Y > 0 - CompletionLeniency && P2Position.Y < 0 + CompletionLeniency))
		{
			if(CompletionTimePlayer2 < CompletionHoldTime)
			{
				CompletionTimePlayer2 += DeltaTime;

				if(!bPlayer2Aligned)
				{
					bPlayer2Aligned = true;
					//Color is swapped to completed color player 2.
					TVActor.HazeAkComp.HazePostEvent(ColorSwapSuccessAudioEvent);
					SetScalarParam(n"PlayerTwoAligned", 1);
				}
			}
			else if(!bPlayer2Complete && CompletionTimePlayer2 >= CompletionHoldTime)
			{
				bPlayer2Complete = true;
			}
		}
		else
		{
			CompletionTimePlayer2 = 0;
			bPlayer2Complete = false;

			if(bPlayer2Aligned)
			{
				bPlayer2Aligned = false;
				//Color is swapped to incomplete player 2.
				TVActor.HazeAkComp.HazePostEvent(ColorSwapFailAudioEvent);
				SetScalarParam(n"PlayerTwoAligned", 0);
				if(TVActor.HazeAkComp.EventInstanceIsPlaying(ScreenDistortionEventInstance))
				{
					TVActor.HazeAkComp.HazePostEvent(StopScreenDistortionAudioEvent);
				}
				
			}
		}

		if(bPlayer1Aligned && bPlayer2Aligned)
		{
			if(DistortionTimeLike.GetValue() < 1)
			{
				DistortionTimeLike.Play();
			}

			if(!bPlayersAligned)
			{
				ScreenDistortionEventInstance = TVActor.HazeAkComp.HazePostEvent(ScreenDistortionAudioEvent);
				bPlayersAligned = true;
			}
				
		}
		else
		{
			bPlayersAligned = false;

			if(DistortionTimeLike.GetValue() > 0)
				DistortionTimeLike.Reverse();
		}

		if(bPlayer1Complete && bPlayer2Complete)
		{
			if(HasControl())
			{
				TVActor.SwitchInputEnabled(false);
				TriggerCompletion();
			}
		}
	}

	UFUNCTION(NetFunction)
	void TriggerCompletion()
	{
		bLevelCompleted = true;

		if(bIsStartLevel)
		{
			OnProgressFinished();
		}
		else
		{
			if(bIsFinalLevel)
			{
				TVActor.DisableInteractionExit();
			}
			ProgressTimeLike.Play();
		}
	}

	void ValidatePlayer1Playing()
	{
		if(!IsActioning(n"Player1Playing"))
		{
			if(TVActor.Player1Position != Player1Start && !ResetTimeLikeP1.IsPlaying())
			{
				ResetTimeLikeP1.PlayFromStart();
			}
		}
		else
		{
			if(ResetTimeLikeP1.IsPlaying())
				ResetTimeLikeP1.Stop();
		}	
	}

	void ValidatePlayer2Playing()
	{
		if(!IsActioning(n"Player2Playing"))
		{
			if(TVActor.Player2Position != Player2Start && !ResetTimeLikeP2.IsPlaying())
			{
				ResetTimeLikeP2.PlayFromStart();
			}
		}
		else
		{
			if(ResetTimeLikeP2.IsPlaying())
				ResetTimeLikeP2.Stop();
		}	
	}

	UFUNCTION()
	void ResetPlayer1OnUpdate(float Value)
	{
		float NewX = 0.f;
		float NewY = 0.f;

		if(bMayLoopOnLeftSide)
		{
			if(P1Position.X >= P1LoopingLimits.X)
				NewX = FMath::Lerp(P1Position.X, Player1Start.X, Value);
			else if(P1Position.X < P1LoopingLimits.X)
				NewX = FMath::Lerp(P1Position.X, Player1Start.X, -Value);
		}
		else
		{
			if(P1Position.X >= P1LoopingLimits.X)
				NewX = FMath::Lerp(P1Position.X, Player1Start.X, -Value);
			else if(P1Position.X < P1LoopingLimits.X)
				NewX = FMath::Lerp(P1Position.X, Player1Start.X, Value);
		}

		if(bMayLoopOnUpperSide)
		{
			if(P1Position.Y >= P1LoopingLimits.Y)
				NewY = FMath::Lerp(P1Position.Y, Player1Start.Y, Value);
			else if(P1Position.Y < P1LoopingLimits.Y)
				NewY = FMath::Lerp(P1Position.Y, Player1Start.Y, -Value);
		}
		else
		{
			if(P1Position.Y >= P1LoopingLimits.Y)
				NewY = FMath::Lerp(P1Position.Y, Player1Start.Y, -Value);
			else if(P1Position.Y < P1LoopingLimits.Y)
				NewY = FMath::Lerp(P1Position.Y, Player1Start.Y, Value);
		}

		FVector2D NewPosition = FVector2D(NewX, NewY);
		TVActor.Player1Position = NewPosition;
	}

	UFUNCTION()
	void ResetPlayer2OnUpdate(float Value)
	{
		float NewX = 0.f;
		float NewY = P2Position.Y;

		if(bCodyLoopOnLeftSide)
		{
			if(P2Position.X >= P2LoopingLimits.X)
				NewX = FMath::Lerp(P2Position.X, Player2Start.X, Value);
			else if(P2Position.X < P2LoopingLimits.X )
				NewX = FMath::Lerp(P2Position.X, Player2Start.X, -Value);
		}
		else
		{
			if(P2Position.X >= P2LoopingLimits.X)
				NewX = FMath::Lerp(P2Position.X, Player2Start.X, -Value);
			else if(P2Position.X < P2LoopingLimits.X )
				NewX = FMath::Lerp(P2Position.X, Player2Start.X, Value);
		}

		if(bCodyLoopOnUpperSide)
		{
			if(P2Position.Y >= P2LoopingLimits.Y)
				NewY = FMath::Lerp(P2Position.Y, Player2Start.Y, Value);
			else if(P2Position.Y < P2LoopingLimits.Y)
				NewY = FMath::Lerp(P2Position.Y, Player2Start.Y, -Value);
		}
		else
		{
			if(P2Position.Y >= P2LoopingLimits.Y)
				NewY = FMath::Lerp(P2Position.Y, Player2Start.Y, -Value);
			else if(P2Position.Y < P2LoopingLimits.Y)
				NewY = FMath::Lerp(P2Position.Y, Player2Start.Y, Value);
		}

		FVector2D NewPosition = FVector2D(NewX, NewY);
		TVActor.Player2Position = NewPosition;
	}


	UFUNCTION()
	void OnProgressUpdate(float Value)
	{
		float NewProgress = FMath::Lerp(CurrentProgress, LevelCompleteProgress, Value);
		TVActor.InteractionProgress = NewProgress;
		SetScalarParam(n"Hackedness", NewProgress);
	}

	//Start Distortion Timelike For blending into next screen.
	UFUNCTION()
	void OnProgressFinished()
	{
		CompletionTimeLike.Play();
	}

	UFUNCTION()
	void OnDistortionUpdate(float Value)
	{
		SetScalarParam(n"BothAligned", Value);
	}

	UFUNCTION()
	void OnDistortionFinished()
	{

	}

	UFUNCTION()
	void OnCompletionUpdate(float Value)
	{
		SetScalarParam(n"Success", Value);

		if(bReversingCompletion)
		{
			float NewValue = FMath::Lerp(0.f, 0.2f, Value);

			TVActor.ApplySpecificForceFeedback(NewValue);
		}
	}

	UFUNCTION()
	void OnCompletionFinished()
	{
		if(bLevelCompleted && HasControl())
		{
			TVActor.ChangeState(Nextlevel);
		}
		
		bReversingCompletion = false;
	}

	void SetScalarParam(FName ParamName, float Value)
	{
		TVActor.BaseMesh.SetScalarParameterValueOnMaterialIndex(MaterialIndexToUse, ParamName, Value);
	}

	void SetPositionParam(FName ParamName, FLinearColor Value)
	{
		TVActor.BaseMesh.SetColorParameterValueOnMaterialIndex(MaterialIndexToUse, ParamName, Value);
	}

	void ResetState()
	{
		bPlayer1Complete = false;
		bPlayer2Complete = false;
		bLevelCompleted = false;
		CompletionTimePlayer1 = 0.f;
		CompletionTimePlayer2 = 0.f;
	}

	void ApplyForceFeedback()
	{
		if(bPlayer1Aligned && bPlayer2Aligned)
			TVActor.ApplyForceFeedback();
	}
}