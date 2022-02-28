import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

// Controls location of the ball
class URodFishBallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RodFishBallCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	//*** GENERAL INFO ***//
	ARodBase RodBase;
	bool bLineOutCheck;
	bool bIsCastingCheck;
	bool bRemoteSnappedToReelAlpha;
	bool bRemoteSnappedToHaulAlpha;
	bool bBackAtDefault;

	//*** MAIN BEZIER TRAJECTORY ***//
	float AlphaCast;
	FVector A;
	FVector B;
	FVector ControlPoint;
	FVector FishBallForward;
	FVector NextLoc;
	FQuat NewRot;

	//*** REEL BEZIER TRAJECTORY ***//
	float MaxReelAlpha;
	FVector FailReelLocation;
	FVector EndReelLocation;
	FVector HoldLocation;

	//*** BALL SPEED ***//
	float SpeedAdjustment;
	float SpeedDefault = 0.85f; 
	float SpeedAdjustMultiplyUp = 1.021f;
	float SpeedAdjustMultiplyDown = 0.9976f;
	float MinHaulDistance = 10.f;
	
	//*** FISH MOVEMENT DIRECTION ***//
	float NewChangeDirectionTime;
	float MinChangeDirectionRate = 0.2f;
	float MaxChangeDirectionRate = 0.4f;
	float VectorOffsetValue = 85.f;
	FVector FishOffsetLoc;
	FVector AddedLoc;

	//*** NETWORKING ***//
	float NetworkTime;
	float NetworkRate = 0.35f;
	float NetworkAcceleratedDefaultTime = 2.8f;
	float NetworkAcceleratedCastTime = 1.2f;
	
	FVector NetReelBallLocation;
	FVector RemoteReelBallLocation;
	FHazeAcceleratedVector AcceleratedReelBall;

	FHazeAcceleratedFloat AcceleratedReelinput;
	EFishingState NetFishingState;

	//FHazeAcceleratedVector AcceleratedNewLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		RodBase = Cast<ARodBase>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SpeedAdjustment = SpeedDefault;
	}

	void CastTrajectory()
	{
		FishBallForward = RodBase.BaseSkeleton.ForwardVector * RodBase.PlayerComp.StoredCastPower;

		A = RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket");
		B = RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket");
		B += FishBallForward;
		B += FVector(0,0, -600.f);
		
		FVector ForwardDirection = A - B;
		ForwardDirection.Normalize();

		ControlPoint = (A + B) * 0.5f;
		ControlPoint += FVector(0.f,0.f,1350.f);
		ControlPoint -=  ForwardDirection * 350.f;
	}

	void ReelTrajectory()
	{
		EndReelLocation = RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket") - FVector(0.f, 0.f, 750.f);
		FailReelLocation = B;
		FVector Direction = FailReelLocation - EndReelLocation;
		float ExtraPercent = Direction.Size() * RodBase.PlayerComp.AlphaStartingValue;
		Direction.Normalize();   
		FailReelLocation += Direction * ExtraPercent;

		ControlPoint = (FailReelLocation + EndReelLocation) * 0.5f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if(RodBase.PlayerComp != nullptr)
			{
				HoldLocation = RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket") + FVector(0.f, 0.f, -150.f);

				switch(RodBase.PlayerComp.FishingState)
				{
					case EFishingState::Default:
						AddedLoc = FVector(0.f);
						DefaultBallState(DeltaTime);
					break;

					case EFishingState::WindingUp:
						AddedLoc = FVector(0.f);
						DefaultBallState(DeltaTime);
					break;

					case EFishingState::Casting:
						AddedLoc = FVector(0.f);
						CastTrajectory();
						Casting(DeltaTime);
					break;

					case EFishingState::Reeling:
						ReelTrajectory();
						Reeling(DeltaTime);
					break;

					case EFishingState::Hauling:
						AddedLoc = FVector(0.f);
						Hauling(DeltaTime);
					break;

					case EFishingState::HoldingCatch:
						AddedLoc = FVector(0.f);
						Hauling(DeltaTime);
					break;

					case EFishingState::ThrowingCatch:
						AddedLoc = FVector(0.f);
						ThrowingCatch(DeltaTime);
					break;
				}

				if (NetworkTime <= System::GameTimeInSeconds)
				{
					NetworkTime = System::GameTimeInSeconds + NetworkRate;
					NetOurFishingState(RodBase.PlayerComp.FishingState);
					NetOurReelingLocation(RodBase.FishingBall.WorldLocation);
				}

				RodBase.PlayerComp.FishballLoc = RodBase.FishingBall.WorldLocation;
			}
			else
			{
				DefaultBallState(DeltaTime);
			}

		}
		else
		{
			if(RodBase.PlayerComp != nullptr)
			{
				switch(NetFishingState)
				{
					case EFishingState::Default:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToReelAlpha = false;
						bRemoteSnappedToHaulAlpha = false;
						DefaultBallState(DeltaTime);
					break;

					case EFishingState::WindingUp:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToReelAlpha = false;
						bRemoteSnappedToHaulAlpha = false;
						DefaultBallState(DeltaTime);
					break;

					case EFishingState::Casting:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToReelAlpha = false;
						bRemoteSnappedToHaulAlpha = false;
						CastTrajectory();
						Casting(DeltaTime);
					break;

					case EFishingState::Reeling:
						bRemoteSnappedToHaulAlpha = false;
						ReelTrajectory();
						Reeling(DeltaTime);
					break;

					case EFishingState::Hauling:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToReelAlpha = false;
						Hauling(DeltaTime);
					break;

					case EFishingState::HoldingCatch:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToReelAlpha = false;
						Hauling(DeltaTime);
					break;

					case EFishingState::ThrowingCatch:
						AddedLoc = FVector(0.f);
						bRemoteSnappedToHaulAlpha = false;
						bRemoteSnappedToReelAlpha = false;
						ThrowingCatch(DeltaTime);
					break;
				}
				
				RodBase.PlayerComp.FishballLoc = RodBase.FishingBall.WorldLocation;
			}
			else
			{
				DefaultBallState(DeltaTime);
			}
		}
	}

	void DefaultBallState(float DeltaTime)
	{
		if (!bBackAtDefault)
		{
			RodBase.AudioLineBackToDefault();
			bBackAtDefault = true;
		}
		
		RodBase.FishingBall.SetWorldLocation(RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket"));
		
	}

	void Casting(float DeltaTime)
	{
		if (AlphaCast < 1.f)
		{
			AlphaCast += SpeedAdjustment * DeltaTime;
			NextLoc = Math::GetPointOnQuadraticBezierCurve(A, ControlPoint, B, AlphaCast);
			RodBase.FishingBall.SetWorldLocation(NextLoc);
			
			if (AlphaCast > 0.6f)
				SpeedAdjustment *= SpeedAdjustMultiplyUp;
			else
				SpeedAdjustment *= SpeedAdjustMultiplyDown;
		}
		else
		{
			if (HasControl())
				RodBase.PlayerComp.FishingState = EFishingState::Catching;
			else
				NetFishingState = EFishingState::Catching;
			
			AlphaCast = 0.f;
			SpeedAdjustment = SpeedDefault;
		}

		bBackAtDefault = false;
	}

	void Reeling(float DeltaTime)
	{
		if (RodBase.PlayerComp.AlphaPlayerReel < 1.f)
		{
			if (HasControl())
			{
				NextLoc = Math::GetPointOnQuadraticBezierCurve(FailReelLocation, ControlPoint, EndReelLocation, RodBase.PlayerComp.AlphaPlayerReel);

				if (NewChangeDirectionTime <= System::GameTimeInSeconds)
				{
					float RandomX = FMath::RandRange(-VectorOffsetValue, VectorOffsetValue);
					float RandomY = FMath::RandRange(-VectorOffsetValue, VectorOffsetValue);

					FishOffsetLoc = FVector(RandomX, RandomY, 0.f);

					float R = FMath::RandRange(MinChangeDirectionRate, MaxChangeDirectionRate);
					NewChangeDirectionTime = System::GameTimeInSeconds + R;
				}

				AddedLoc = FMath::VInterpConstantTo(AddedLoc, FishOffsetLoc, DeltaTime, 350.f);

				NextLoc += AddedLoc;

				RodBase.FishingBall.SetWorldLocation(NextLoc);
			}
		}
		else
		{
			if (HasControl())
				RodBase.PlayerComp.FishingState = EFishingState::Hauling;
		}

		if (!HasControl())
		{
			if (!bRemoteSnappedToReelAlpha)
			{
				AcceleratedReelBall.SnapTo(RodBase.FishingBall.WorldLocation);
				bRemoteSnappedToReelAlpha = true;
			}

			AcceleratedReelBall.AccelerateTo(NetReelBallLocation, 2.f, DeltaTime);
			RodBase.FishingBall.SetWorldLocation(AcceleratedReelBall.Value);
		}

		bBackAtDefault = false;
	}

	void Hauling(float DeltaTime)
	{
		if (HasControl())
		{
			// NextLoc = FMath::VInterpConstantTo(RodBase.FishingBall.WorldLocation, HoldLocation, DeltaTime, 600.f);
			NextLoc = FMath::VInterpTo(RodBase.FishingBall.WorldLocation, HoldLocation, DeltaTime, 3.5f);
			RodBase.FishingBall.SetWorldLocation(NextLoc);
		}

		float HaulingDistance = (HoldLocation - RodBase.FishingBall.WorldLocation).Size();

		if (!RodBase.PlayerComp.bHaulingUpcatch && HaulingDistance > MinHaulDistance)
		{
			RodBase.PlayerComp.bHaulingUpcatch = true;	
		}	
		else if (RodBase.PlayerComp.bHaulingUpcatch && HaulingDistance <= MinHaulDistance)
		{
			RodBase.PlayerComp.bHaulingUpcatch = false;

			if (HasControl())
				RodBase.PlayerComp.FishingState = EFishingState::HoldingCatch;
		}

		if (!HasControl())
		{
			if (!bRemoteSnappedToHaulAlpha)
			{
				AcceleratedReelBall.SnapTo(RodBase.FishingBall.WorldLocation);
				bRemoteSnappedToHaulAlpha = true;
			}

			AcceleratedReelBall.AccelerateTo(NetReelBallLocation, 1.3f, DeltaTime);
			RodBase.FishingBall.SetWorldLocation(AcceleratedReelBall.Value);
		}

		bBackAtDefault = false;
	}

	void ThrowingCatch(float DeltaTime)
	{
		NextLoc = FMath::VInterpConstantTo(RodBase.FishingBall.WorldLocation, RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket"), DeltaTime, 2000.f);
		RodBase.FishingBall.SetWorldLocation(NextLoc);
		bBackAtDefault = false;
	}

	UFUNCTION(NetFunction)
	void NetOurReelingLocation(FVector InputLocation)
	{
		NetReelBallLocation = InputLocation;
	}

	UFUNCTION(NetFunction)
	void NetOurFishingState(EFishingState InputFishingState)
	{
		if (InputFishingState != EFishingState::Catching)
		{
			NetFishingState = InputFishingState;
			RodBase.PlayerComp.FishingState = InputFishingState;
		}
	}
}