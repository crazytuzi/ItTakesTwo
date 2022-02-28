import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetWheelComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;

class UMagneticWheelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

    AMagneticWheelActor MagneticWheelActor;

	float AngularVelocity = 0.0f;
	float Drag = 2.3f;
	float Acceleration = 0.7f;

	float SpinBackSpeed = 100.0f;

	bool bSpinBack = false;

	bool bBackToOriginal = false;

	bool bCannotBeSpunBelowMinRotation = false;
	float MinRotation = -10.0f;

	bool bHasMaxRotation = false;
	float MaxRotation = 500.0f;

	bool bStayAtMax = false;
	bool bReachedMaxRotation = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagneticWheelActor = Cast<AMagneticWheelActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bStayAtMax && bReachedMaxRotation)
			return EHazeNetworkActivation::DontActivate;

        if (MagneticWheelActor.ActiveMagneticComponents.Num() > 0)
			return EHazeNetworkActivation::ActivateFromControl;

        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagneticWheelActor.ActiveMagneticComponents.Num() > 0)
            return EHazeNetworkDeactivation::DontDeactivate;

		if(!bSpinBack && !FMath::IsNearlyZero(AngularVelocity, 0.1f))
            return EHazeNetworkDeactivation::DontDeactivate;

		if(!StoppedAtMaxOrMin())
            return EHazeNetworkDeactivation::DontDeactivate;
			

			
        else
            return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	bool StoppedAtMaxOrMin() const
	{
		if(bHasMaxRotation && bStayAtMax)
			if(bReachedMaxRotation)
				return true;
			
		if(bSpinBack)
			if(bBackToOriginal)
				return true;            

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(MagneticWheelActor.WheelSettings != nullptr)
		{
			Drag = MagneticWheelActor.WheelSettings.Drag;
			Acceleration = MagneticWheelActor.WheelSettings.Acceleration;
			bSpinBack = MagneticWheelActor.WheelSettings.bSpinBack;
			SpinBackSpeed = MagneticWheelActor.WheelSettings.SpinBackSpeed;
			bHasMaxRotation = MagneticWheelActor.WheelSettings.bHasMaxRotation;
			MaxRotation = MagneticWheelActor.WheelSettings.MaxRotation;
			bStayAtMax = MagneticWheelActor.WheelSettings.bStayAtMax;
			bCannotBeSpunBelowMinRotation = MagneticWheelActor.WheelSettings.bCannotBeSpunBelowMinRotation;
			MinRotation = MagneticWheelActor.WheelSettings.MinRotation;
		}

		if(bSpinBack)
			bBackToOriginal = false;
		

		MagneticWheelActor.OnMagneticWheelSpinningStateChanged.Broadcast(true);	
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagneticWheelActor.CurrentVelocity = 0.0f;
		MagneticWheelActor.OnMagneticWheelSpinningStateChanged.Broadcast(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MagneticWheelActor.HasControl())
		{
			MagneticWheelActor.SyncProgress.Value = MagneticWheelActor.Progress;
			MagneticWheelActor.SyncVelocity.Value = MagneticWheelActor.CurrentVelocity;
			MagneticWheelActor.SyncRotationComp.Value = MagneticWheelActor.Base.RelativeRotation;

			if(bStayAtMax && bReachedMaxRotation)
				return;

			CalculateVelocity(DeltaTime);

			float DeltaRotation = AngularVelocity * DeltaTime;

			//Return to zero
			if(MagneticWheelActor.ActiveMagneticComponents.Num() <= 0)
			{
				if(bSpinBack)
				{
					if(MagneticWheelActor.AddedRotation > 0 && (MagneticWheelActor.AddedRotation + DeltaRotation) < 0.05f)
					{
						DeltaRotation = MagneticWheelActor.AddedRotation * -1;
					}
					else if(MagneticWheelActor.AddedRotation < 0 && (MagneticWheelActor.AddedRotation + DeltaRotation) > -0.05f)
					{
						DeltaRotation = MagneticWheelActor.AddedRotation * -1;
					}
					
				}
			}
			
			//Don't go over max
			if(bHasMaxRotation)
			{
				if((MagneticWheelActor.AddedRotation + DeltaRotation) > MaxRotation)
				{
					if(!bReachedMaxRotation)
					{
						DeltaRotation = MaxRotation - MagneticWheelActor.AddedRotation;
						NetOnReachedMaxRotation();
						
						bReachedMaxRotation = true;	
					}
					else
						DeltaRotation = 0.0f;
				}
				else
				{
					if(bReachedMaxRotation)
					{
						bReachedMaxRotation = false;
					}
				}
			}

			//Don't go below min
			if(bCannotBeSpunBelowMinRotation)
			{
				if((MagneticWheelActor.AddedRotation + DeltaRotation) < MinRotation)
				{
					DeltaRotation = MinRotation - MagneticWheelActor.AddedRotation;
				}	
			}


			//Add delta rotation
			MagneticWheelActor.Base.AddLocalRotation(FRotator(0, DeltaRotation, 0));
			MagneticWheelActor.AddedRotation += DeltaRotation;
			MagneticWheelActor.CurrentVelocity = DeltaRotation / DeltaTime;

			//Back to original
			if(bSpinBack && MagneticWheelActor.ActiveMagneticComponents.Num() <= 0)
			{
				if(FMath::IsNearlyZero(MagneticWheelActor.AddedRotation, 0.05f))
				{
					bBackToOriginal = true;
					// NOTE THIS HAS TO BE NETWORKED!
					MagneticWheelActor.OnMagneticWheelBackToStart.Broadcast();
				}
			}



			//Check progress
			if(bHasMaxRotation)
			{
				float MinRot = 0.0f;
				float MaxRot = 0.0f;

				if(bCannotBeSpunBelowMinRotation)
					MinRot = MinRotation;
				if(bHasMaxRotation)
					MaxRot = MaxRotation;

				float CurrentProgress = (MagneticWheelActor.AddedRotation-MinRot)/(MaxRot-MinRot);
				MagneticWheelActor.Progress = CurrentProgress;
			}
		}

		// On client we read from data sent by server
		else
		{
			MagneticWheelActor.Progress = MagneticWheelActor.SyncProgress.Value;
			MagneticWheelActor.CurrentVelocity = MagneticWheelActor.SyncVelocity.Value;
			MagneticWheelActor.Base.SetRelativeRotation(MagneticWheelActor.SyncRotationComp.Value);
		}
	}

	UFUNCTION(NetFunction)
	void NetOnReachedMaxRotation()
	{
		MagneticWheelActor.OnMagneticWheelReachedMaxRotation.Broadcast();
	}

	UFUNCTION()
	void CalculateVelocity(float DeltaTime)
	{
		if(MagneticWheelActor.ActiveMagneticComponents.Num() <= 0)
		{
			if(bSpinBack)
			{
				float DeaccelerationSpeed = SpinBackSpeed;

				if(MagneticWheelActor.AddedRotation > 0)
					DeaccelerationSpeed *= -1;

				AngularVelocity += DeaccelerationSpeed * DeltaTime;
				
			}
		}
		else
		{
			for(UMagnetGenericComponent Comp : MagneticWheelActor.ActiveMagneticComponents)
			{
				TArray<FMagnetInfluencer> Influencers;
				Comp.GetInfluencers(Influencers);
				for (const FMagnetInfluencer Influencer : Influencers)
				{
					FVector ToMagnetDir = Comp.WorldLocation - MagneticWheelActor.ActorLocation;
					FVector ToPlayerDir = Influencer.Influencer.ActorLocation - Comp.WorldLocation;

					FVector Forward = MagneticWheelActor.ActorUpVector.CrossProduct(ToMagnetDir);
					Forward.Normalize();
					float Force = ToPlayerDir.DotProduct(Forward);

					if(!Comp.HasOppositePolarity(UMagneticComponent::Get(Influencer.Influencer)))
					{
				 		Force = -Force;
					}
						
					AngularVelocity += Force * Acceleration * DeltaTime;
				}


				AngularVelocity -= AngularVelocity * Drag * DeltaTime;
			}
		}

		AngularVelocity -= AngularVelocity * Drag * DeltaTime;
	}
}