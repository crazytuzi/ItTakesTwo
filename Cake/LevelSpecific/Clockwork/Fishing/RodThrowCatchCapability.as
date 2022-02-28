import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class URodThrowCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RodThrowCatchCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ARodBase RodBase;
	
	//*** GENERAL INFO ***//
	bool bIsThrowing;

	//*** BEZIER CURVE ***//
	FVector A;
	FVector B;
	FVector ControlPoint;
	float ThrowAlpha; 

	//*** THROW SPEEDS ***//
	float ThrowAmount;
	float DefaultThrowSpeed = 1.25f;
	float ReductionMultiplier;
	float SpeedUpMultiplier = 1.001f;
	float SlowDownMultiplier = 0.991f;

	float NewTime;
	float Rate = 0.35f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		RodBase = Cast<ARodBase>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RodBase.PlayerComp != nullptr && RodBase.PlayerComp.FishingState == EFishingState::ThrowingCatch)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (RodBase.PlayerComp.FishingState != EFishingState::ThrowingCatch)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RodBase.DetatchCatch();
		RodBase.CurrentCatch.bCanRotateMesh = true;
		ThrowCatchTrajectory();
		ThrowAlpha = 0.f;
		ThrowAmount = DefaultThrowSpeed;
		bIsThrowing = true;
		NewTime = System::GameTimeInSeconds + Rate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (RodBase.CurrentCatch == nullptr)
			return;

		if (bIsThrowing)
			ThrowingCatch(DeltaTime);

		// if (NewTime <= System::GameTimeInSeconds)
		// 	ThrowCatchTrajectory();

		// for (float Alpha = 0.f; Alpha < 1.f; Alpha += 0.02f)
		// {
		// 	FVector Location = Math::GetPointOnQuadraticBezierCurve(A, ControlPoint, B, Alpha);
		// 	System::DrawDebugPoint(Location, 5.f, FLinearColor::LucBlue);
		// }
	}

	UFUNCTION()
	void ThrowCatchTrajectory()
	{
		A = RodBase.FishingBall.WorldLocation;
		A += FVector(0.f, 0.f, 100.f);
		B = RodBase.FishingCatchPile.ActorLocation;
		B += FVector(0.f, 0.f, 250.f);

		FVector Forward = B - A;
		Forward.Normalize();
		float ForwardAmount = 250.f;

		ControlPoint = (A + B) * 0.5f;
		ControlPoint += FVector(0.f, 0.f, 1080.f);
		ControlPoint += Forward * ForwardAmount;
	}

	UFUNCTION()
	void ThrowingCatch(float DeltaTime)
	{
		if (ThrowAlpha < 1.f)
		{
			//If below 0.5, ThrowAmount becomes less (down to a min of 0.75f as soon as ThrowAlpha reaches 0.5)
			//We know value will be 0.75, so we now multiplier by that + -0.5f (for the difference so that the added value starts on 0 from 0.5 onwards) + ThrowAlpha * 0.5f.
			//ThrowAmount will reach full speed again by the time ThrowAlpha reaches 1.f

			if (ThrowAlpha < 0.6f)
			{
				ReductionMultiplier = 0.62f - (ThrowAlpha * 0.5f);
				ThrowAlpha += (ThrowAmount * ReductionMultiplier) * DeltaTime;
			}
			else
			{
				ThrowAlpha += (ThrowAmount * (ReductionMultiplier + (-0.3f + (ThrowAlpha * 0.75f)))) * DeltaTime;
			}

			FVector NextLoc = Math::GetPointOnQuadraticBezierCurve(A, ControlPoint, B, ThrowAlpha);
			RodBase.CurrentCatch.SetActorLocation(NextLoc);
		}

		// if (ThrowAlpha >= 0.7f && !RodBase.FishingCatchPile.bCanFlingItems)

		if (ThrowAlpha >= 0.98f && !RodBase.FishingCatchPile.bCanFlingItems)
		{
			if (HasControl())
			{
				RodBase.FishingCatchPile.NetRustlePileEffects();
				RodBase.FishingCatchPile.NetBeginFlingSequence();
				System::SetTimer(this, n"NetReturnToDefaultState", 1.7f, false);
			}
			
			bIsThrowing = false;
			RodBase.HideCatch();
		}
	}

	UFUNCTION(NetFunction)
	void NetReturnToDefaultState()
	{
		RodBase.PlayerComp.FishingState = EFishingState::Default;
		RodBase.DisableCatch();
		RodBase.DetatchCatch();
	}
}