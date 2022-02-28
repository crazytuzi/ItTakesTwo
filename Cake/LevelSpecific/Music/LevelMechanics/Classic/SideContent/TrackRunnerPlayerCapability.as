import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.TrackRunnerManager;
import Vino.Movement.Capabilities.TargetRotation.CharacterFaceDirectionCapability;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.TrackRunnerPlayerComponent;

class ATrackRunnerPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TrackRunner");
	default CapabilityDebugCategory = n"TrackRunner";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ATrackRunnerManager TrackRunnerManager;
	AHazePlayerCharacter MyPlayer;
	AKeepInViewCameraActor CameraActor;
	UTrackRunnerPlayerComponent TrackRunnerComponent;
	ASplineActor CurrentSplineToFollow;
	
	float ExpectedImpactDurtionTimer = -1;

	bool LeftSide;
	FStickSnapbackDetector SnapBack;
	float JumpVelocity = 0;
	float TrackChangeTimer;
	bool bTrackChangeActive = false;
	bool bInputStickOverlapp = false;
	bool DifficultyOneActive = true;
	bool DifficultyTwoActive = false;
	bool DifficultyThreeActive = false;

	float Distance; // 0 -> 5000
	float LaneOffset; // -50, 0, 50
	float HeightOffset; 
	float KnockbackAmount;
	int CurrentLane = 0; // -1, 0, 1
	float RunSpeed;


	FVector MyOriginalForwardVector;
	FVector MyOriginalRightVector;
	FVector MyOriginalUpVector;
	FVector RaceOrigin;
	FVector GoalLocation;

	EMovementQueType MovementQue = EMovementQueType::None;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ATrackRunnerManager TrackRunnerLocal = Cast<ATrackRunnerManager>(GetAttributeObject(n"TrackRunner"));
		if(TrackRunnerLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(TrackRunnerLocal.bMiniGameActive == false)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TrackRunnerManager.bMiniGameActive == false)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TrackRunnerComponent = UTrackRunnerPlayerComponent::GetOrCreate(MyPlayer);
		TrackRunnerManager = Cast<ATrackRunnerManager>(GetAttributeObject(n"TrackRunner"));
		TrackRunnerManager.MiniGameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountDownFinished");
		TrackRunnerManager.OnPlayerHitByObstacleForAnimation.AddUFunction(this, n"PlayerImpact");
		TrackRunnerManager.OnStartFinishMiniGame.AddUFunction(this, n"MiniGameFinishing");
		//MyPlayer.Mesh.SetColorParameterValueOnMaterials(n"Emissive Tint", FLinearColor(1,1,1,1));

	//	for (int i = 0; i < MyPlayer.Mesh.Materials.Num(); i++)
	//	{
	//		//MyPlayer.Mesh.SetColorParameterValueOnMaterialIndex(i, n"Emissive Tint", FLinearColor(1,1,1,1));
	//	}

		ChangeDifficulty(1);
		Distance = 0;
		LaneOffset = 0;
		CurrentLane = 0;
		HeightOffset = 0;
		DifficultyOneActive = true;
		DifficultyTwoActive = false;
		DifficultyThreeActive = false;
		GoalLocation = TrackRunnerManager.PlayerTriggerGoalTrigger.GetActorLocation();

		if(MyPlayer == Game::GetMay())
		{
			MyPlayer.AddLocomotionFeature(TrackRunnerManager.MayFeature);
			TrackRunnerManager.MayProgressNetworked.OverrideControlSide(MyPlayer);
		}
		else if(MyPlayer == Game::GetCody())
		{
			MyPlayer.AddLocomotionFeature(TrackRunnerManager.CodyFeature);
			TrackRunnerManager.CodyProgressNetworked.OverrideControlSide(MyPlayer);
		}

		if(TrackRunnerManager.LeftSidePlayer == MyPlayer)
		{
			CheckSides(true);
		}
		else
		{
			CheckSides(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	//	for (int i = 0; i < MyPlayer.Mesh.Materials.Num(); i++)
	//	{
	//		MyPlayer.Mesh.SetColorParameterValueOnMaterialIndex(i, n"Emissive Tint", FLinearColor(0,0,0,0));
	//	}
		
		/*
		if(MyPlayer.HasControl())
		{
			NetworkStartUp(true);
			NetworkDashLeft(false);
			NetworkDashRight(false);
			NetworkImpact(false);
			NetworkJump(false);
		}
		*/

		if(MyPlayer == Game::GetMay())
		{
			MyPlayer.RemoveLocomotionFeature(TrackRunnerManager.MayFeature);
		}
		else if(MyPlayer == Game::GetCody())
		{
			MyPlayer.RemoveLocomotionFeature(TrackRunnerManager.CodyFeature);
		}

		TrackRunnerComponent.DestroyComponent(MyPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
	void CheckSides(bool AmILeft)
	{
		if(MyPlayer == Game::GetMay())
		{
			MyOriginalForwardVector = TrackRunnerManager.LeftPlayerStartLocation.GetActorForwardVector();
			RaceOrigin = TrackRunnerManager.LeftPlayerStartLocation.GetActorLocation();
			MyOriginalRightVector = TrackRunnerManager.LeftPlayerStartLocation.GetActorRightVector();
			MyOriginalUpVector = TrackRunnerManager.LeftPlayerStartLocation.GetActorUpVector();

			LeftSide = true;
			CurrentSplineToFollow = TrackRunnerManager.SplineLeftSide2;
		}
		else
		{
			MyOriginalForwardVector = TrackRunnerManager.RightPlayerStartLocation.GetActorForwardVector();
			RaceOrigin = TrackRunnerManager.RightPlayerStartLocation.GetActorLocation();
			MyOriginalRightVector = TrackRunnerManager.RightPlayerStartLocation.GetActorRightVector();
			MyOriginalUpVector = TrackRunnerManager.RightPlayerStartLocation.GetActorUpVector();

			LeftSide = false;
			CurrentSplineToFollow = TrackRunnerManager.SplineRightSide2;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CountDownFinished()
	{
		if(MyPlayer.HasControl())
		{
			NetworkStartUp(false);
		}
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"TrackRunner";
		MyPlayer.RequestLocomotion(Locomotion);

		TrackRunnerComponent.bRun = TrackRunnerManager.bStartRunAnimation;

		float DistanceFromGoal = GoalLocation.DistXY(MyPlayer.ActorLocation);
		//PrintToScreen("DistanceFromGoal " + DistanceFromGoal + "       MyPlayer " + MyPlayer);
		if(DistanceFromGoal <= 3350)
		{
			//PrintToScreen("3");
			if(!DifficultyThreeActive)
			{
				DifficultyThreeActive = true;
				ChangeDifficulty(3);
			}
		}
		if(DistanceFromGoal >= 3350 && DistanceFromGoal <= 4950)
		{
			//PrintToScreen("2");
			if(!DifficultyTwoActive)
			{
				DifficultyTwoActive = true;
				ChangeDifficulty(2);
			}
		}
		if(DistanceFromGoal >= 4950)
		{
			//PrintToScreen("1");
			if(!DifficultyOneActive)
			{
				DifficultyOneActive = true;
				ChangeDifficulty(1);
			}
		}

		if(TrackRunnerComponent.bStartUp)
			return;

		///Run forward
		if(KnockbackAmount > 0.1f)
		{
			if(MyPlayer.HasControl())
			{
				float DeltaKnockback = KnockbackAmount * 5.f * DeltaTime;
				KnockbackAmount -= DeltaKnockback;

				if(DistanceFromGoal <= 5180)
				{
					Distance -= DeltaKnockback;
				}
				else
				{
					KnockbackAmount = 0;
				}
			}
		}
		else
		{
			if(DistanceFromGoal <= 5375)
				RunSpeed = 200;
			if(DistanceFromGoal > 5375)
				RunSpeed = 350;

			Distance += RunSpeed * DeltaTime;
		}

		//DEBUGGING PURPOSES
		float TargetLaneOffset = CurrentLane * 170.f;
		LaneOffset = FMath::Lerp(LaneOffset, TargetLaneOffset, 9.5f * DeltaTime);
		FVector ActorLocation = RaceOrigin + MyOriginalForwardVector * Distance + MyOriginalRightVector * LaneOffset + MyOriginalUpVector * HeightOffset;
		MyPlayer.SetActorLocation(ActorLocation);

		//PrintToScreen("MyPlayer.SetActorLocation(ActorLocation) " + MyPlayer.GetActorLocation() + Owner);
		//PrintToScreen("KnockbackAmount " + KnockbackAmount);
		//PrintToScreen("ActorLocation " + ActorLocation);


		//Jumping
		if(WasActionStarted(ActionNames::MovementJump))
		{
			Jump();
		}
		if(TrackRunnerComponent.bJump)
		{
			float Acceleration = 6000.f * DeltaTime;
			JumpVelocity -= Acceleration;
			HeightOffset += JumpVelocity * DeltaTime;

			if(HeightOffset <= 0)
			{
				HeightOffset = 0;
				if(MyPlayer.HasControl())
				{
					NetworkJump(false);
				}
			}

			//PrintToScreen("HeightOffset " + HeightOffset);
		}
		

		//Move cross lanes
		FVector PlayerLeftStickInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		PlayerLeftStickInput = SnapBack.RemoveStickSnapbackJitter(PlayerLeftStickInput, PlayerLeftStickInput);
		if(PlayerLeftStickInput.X < -0.4f)
		{
			if(!SnapBack.bDetectedSnapback)
			{
				MoveToNewLane(true);
			}	
		}
		else if(PlayerLeftStickInput.X > 0.4f)
		{
			if(!SnapBack.bDetectedSnapback)
			{
				MoveToNewLane(false);
			}
		}



		if(ExpectedImpactDurtionTimer > 0)
		{
			if(Time::GetGameTimeSeconds() >= ExpectedImpactDurtionTimer)
			{
				ExpectedImpactDurtionTimer = -1;
				if(MyPlayer.HasControl())
				{
					NetworkImpact(false);
				}
			}
		}
		if(bTrackChangeActive)
		{
			TrackChangeTimer -= DeltaTime * 4.0f;
			if(TrackChangeTimer <= 0)
			{
				bTrackChangeActive = false;
				if(MyPlayer.HasControl())
				{
					NetworkDashLeft(false);
					NetworkDashRight(false);
				}
			}
		}


		if(MyPlayer.HasControl())
		{
			if(MyPlayer == Game::GetCody())
			{
				TrackRunnerManager.CodyProgressNetworked.Value = MyPlayer.GetActorLocation();
			}
			if(MyPlayer == Game::GetMay())
			{
				TrackRunnerManager.MayProgressNetworked.Value = MyPlayer.GetActorLocation();
			}
		}
		else
		{
			if(MyPlayer == Game::GetCody())
			{
				MyPlayer.SetActorLocation(FVector(TrackRunnerManager.CodyProgressNetworked.Value));
			}
			if(MyPlayer == Game::GetMay())
			{
				MyPlayer.SetActorLocation(FVector(TrackRunnerManager.MayProgressNetworked.Value));
			}
		}
	}

	UFUNCTION()
	void ChangeDifficulty(int NewDifficulty)
	{
		if(NewDifficulty == 1)
		{
			if(TrackRunnerManager.HasControl())
			{
				DifficultyTwoActive = false;
				DifficultyThreeActive = false;
				TrackRunnerManager.ChangeDifficulty(MyPlayer, 1);
			} 
		}
		if(NewDifficulty == 2)
		{
			if(TrackRunnerManager.HasControl())
			{
				DifficultyOneActive = false;
				DifficultyThreeActive = false;
				TrackRunnerManager.ChangeDifficulty(MyPlayer, 2);
			} 
		}
		if(NewDifficulty == 3)
		{
			if(TrackRunnerManager.HasControl())
			{
				DifficultyOneActive = false;
				DifficultyTwoActive = false;
				TrackRunnerManager.ChangeDifficulty(MyPlayer, 3);
			} 	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Jump()
	{
		if(TrackRunnerComponent.bJump)
			return;
	//	MovementQue = EMovementQueType::Jump;
	//	if(TrackRunnerComponent.bDashRight or TrackRunnerComponent.bDashLeft)
		//	return;
		
		MovementQue = EMovementQueType::None;
		JumpVelocity = 1750.f;

		if(MyPlayer.HasControl())
		{
			NetworkJump(true);
		}
	}

	UFUNCTION()
	void PlayerImpact(AHazePlayerCharacter Player)
	{
		if(MyPlayer == Player)
		{
			KnockbackAmount += 500.f;
			ExpectedImpactDurtionTimer = Time::GetGameTimeSeconds() + 0.2f;

			if(MyPlayer.HasControl())
			{
				MyPlayer.PlayForceFeedback(TrackRunnerManager.ImpactForceFeedback, false, true, n"TrackRunnerImpact");
				NetworkImpact(true);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void MoveToNewLane(bool bLeft)
	{
		if(bTrackChangeActive)
			return; 

		if(bLeft == true)
		{
			MovementQue = EMovementQueType::DashLeft;
		}
		else
		{
			MovementQue = EMovementQueType::DashRight;
		}


		MovementQue = EMovementQueType::None;
		if(bLeft == true)
		{
			if(CurrentLane == 0)
			{
				if(MyPlayer.HasControl())
				{
					bTrackChangeActive = true;
					TrackChangeTimer = 1;
					NetworkDashLeft(true);
					CurrentLane = -1;
				}
			}
			if(CurrentLane == 1)
			{
				if(MyPlayer.HasControl())
				{
					bTrackChangeActive = true;
					TrackChangeTimer = 1;
					NetworkDashLeft(true);
					CurrentLane = 0;
				}
			}
		}
		else
		{
			if(CurrentLane == 0)
			{
				if(MyPlayer.HasControl())
				{
					bTrackChangeActive = true;
					TrackChangeTimer = 1;
					NetworkDashRight(true);
					CurrentLane = 1;
				}
			}
			if(CurrentLane == -1)
			{
				if(MyPlayer.HasControl())
				{
					bTrackChangeActive = true;
					TrackChangeTimer = 1;
					NetworkDashRight(true);
					CurrentLane = 0;
				}
			}
		}
	}

	UFUNCTION()
	void CheckQuedMovement()
	{
		if(MovementQue == EMovementQueType::Jump)
		{
			Jump();
		}
		if(MovementQue == EMovementQueType::DashLeft)
		{
			MoveToNewLane(true);
		}
		if(MovementQue == EMovementQueType::DashRight)
		{
			MoveToNewLane(false);
		}
	}

	UFUNCTION()
	void MiniGameFinishing()
	{
		if(MyPlayer.HasControl())
		{
			NetworkStartUp(true);
		}
	}

	UFUNCTION(NetFunction)
	void NetworkImpact(bool bIsImpacting)
	{
		if(bIsImpacting == true)
		{
			if(TrackRunnerComponent != nullptr)
				TrackRunnerComponent.bImpact = true;
		}
		else
		{
			if(TrackRunnerComponent != nullptr)
				TrackRunnerComponent.bImpact = false;
		}
	}
	UFUNCTION(NetFunction)
	void NetworkJump(bool bIsJumping)
	{
		if(bIsJumping == true)
		{
			if(TrackRunnerComponent != nullptr)
				TrackRunnerComponent.bJump = true;
		}
		else
		{
			if(TrackRunnerComponent != nullptr)
			{
				TrackRunnerComponent.bJump = false;
				CheckQuedMovement();
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetworkDashRight(bool bIsDashingRight)
	{
		if(TrackRunnerComponent != nullptr)
		{
			if(bIsDashingRight == true)
			{
				if(!TrackRunnerComponent.bJump)
				{
					TrackRunnerComponent.bDashRight = true;
				}
			}
			else
			{
				TrackRunnerComponent.bDashRight = false;
				CheckQuedMovement();
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetworkDashLeft(bool bIsDashingLeft)
	{
		if(TrackRunnerComponent != nullptr)
		{
			if(bIsDashingLeft == true)
			{
				if(!TrackRunnerComponent.bJump)
				{
					TrackRunnerComponent.bDashLeft = true;
				}
			}
			else
			{
				TrackRunnerComponent.bDashLeft = false;
				CheckQuedMovement();
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetworkStartUp(bool bIsStartingUp)
	{
		if(TrackRunnerComponent != nullptr)
		{
			if(bIsStartingUp == true)
			{
				TrackRunnerComponent.bStartUp = true;
			}
			else
			{
				TrackRunnerComponent.bStartUp = false;
			}

			if(MyPlayer == Game::GetCody())
				Game::GetCody().SetActorRotation(TrackRunnerManager.SplineRightSide2.GetActorRotation());
			if(MyPlayer == Game::GetMay())
				Game::GetCody().SetActorRotation(TrackRunnerManager.SplineLeftSide2.GetActorRotation());
		}
	}
}

enum EMovementQueType
{
	None,
	Jump,
	DashLeft,
	DashRight,
}