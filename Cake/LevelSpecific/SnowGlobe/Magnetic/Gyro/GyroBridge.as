import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class AGyroBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GyroRoot;

	UPROPERTY(DefaultComponent, Attach = GyroRoot)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent BridgePivot;

	UPROPERTY(DefaultComponent, Attach = BridgePivot)
	UMagnetGenericComponent MagneticComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UHazeAkComponent HazeAkCompLeftRail;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UHazeAkComponent HazeAkCompRightRail;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartGyroBridgeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopGyroBridgeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartGyroRailAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopGyroRailAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bAutoDisable = true;
	default Disable.AutoDisableRange = 7000.f;
	default Disable.bActorIsVisualOnly = true;
	default Disable.bRenderWhileDisabled = true;

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	float MagneticPower = 200.f;

	FVector AngularVelocity;

	FQuat Pitch;
	FQuat Yaw;

	float NextSyncTime = 0.f;
	FQuat ControlPitch;
	FQuat ControlYaw;

	bool bIsGyroMoving = false;

	TArray<UMagnetGenericComponent> MagnetComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Set yaw and pitch to its initial values
		ControlYaw = Yaw = BasePivot.RelativeRotation.Quaternion();
		ControlPitch = Pitch = BridgePivot.RelativeRotation.Quaternion();
		SetControlSide(Game::May);

		// Find all magnets
		TArray<USceneComponent> Children;
		BridgePivot.GetChildrenComponents(true, Children);
		for(auto Child : Children)
		{
			auto Magnet = Cast<UMagnetGenericComponent>(Child);
			if (Magnet == nullptr)
				continue;

			MagnetComponents.Add(Magnet);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Torque; 
		for(auto Magnet : MagnetComponents)
		{
			FVector MageticForce = Magnet.GetDirectionalForceFromAllInfluencers() * MagneticPower;

			Torque += GetPivotTorque(Magnet.WorldLocation, MageticForce, BasePivot.WorldLocation, BasePivot.UpVector);
			Torque += GetPivotTorque(Magnet.WorldLocation, MageticForce, BridgePivot.WorldLocation, BridgePivot.RightVector);
		}

		Torque -= AngularVelocity * Drag;

	//	System::DrawDebugLine(MagneticComponent.WorldLocation, MagneticComponent.WorldLocation + MageticForce * 100.f, FLinearColor::Yellow, 0.f, 10.f);
	//	System::DrawDebugLine(MagneticComponent.WorldLocation, MagneticComponent.WorldLocation + AngularVelocity * 100.f, FLinearColor::Green, 0.f, 10.f);
	//	System::DrawDebugLine(MagneticComponent.WorldLocation, MagneticComponent.WorldLocation + Torque * 100.f, FLinearColor::Red, 0.f, 10.f);

		AngularVelocity += Torque * DeltaTime;

		FQuat CurrentRotation = Yaw * Pitch;

		FQuat DeltaRotation = FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);

		FQuat NextRotation = DeltaRotation * CurrentRotation;

//		FQuat NextRotation = (Yaw * YawDelta) * (Pitch * PitchDelta);

		float ConstrainDot = NextRotation.ForwardVector.DotProduct(FVector::ForwardVector);

		/*
		if (ConstrainDot < -0.05f)
		{
			FVector ImpactDirection = NextRotation.ForwardVector.ConstrainToPlane(FVector::ForwardVector);
		
			FVector AngularNormal = -ImpactDirection.CrossProduct(FVector::ForwardVector);

			float PitchDot = AngularNormal.DotProduct(AngularVelocity.ConstrainToDirection(Yaw.RightVector));
			float YawDot = AngularNormal.DotProduct(AngularVelocity.ConstrainToDirection(Yaw.UpVector));
			Print("PitchDot: " + PitchDot + "YawDot: " + YawDot);

			if (PitchDot > YawDot)
				AngularVelocity -= Yaw.RightVector * PitchDot;
			else
				AngularVelocity -= Yaw.UpVector * YawDot;


		}
		*/
		float YawVelocity = AngularVelocity.DotProduct(Yaw.UpVector);
		FQuat YawDelta = FQuat(FVector::UpVector, YawVelocity * DeltaTime);

		float PitchVelocity = AngularVelocity.DotProduct(Yaw.RightVector);
		FQuat PitchDelta = FQuat(FVector::RightVector, PitchVelocity * DeltaTime);

		Yaw = Yaw * YawDelta;
		Pitch = Pitch * PitchDelta;

		float TorqueNormalized = FMath::Abs(FMath::GetMappedRangeValueClamped(FVector2D(-0.5f, 0.5f), FVector2D(-1.f, 1.f), Torque.X));	
		HazeAkComp.SetRTPCValue("Rtpc_SnowGlobe_Lake_GyroBridge_Velocity", TorqueNormalized);	

		float RailsVelocity = FMath::Abs(FMath::GetMappedRangeValueClamped(FVector2D(-0.3f, 0.3f), FVector2D(-1.f, 1.f), YawVelocity));
		HazeAkCompLeftRail.SetRTPCValue("Rtpc_SnowGlobe_Lake_GyroBridge_Rails_Velocity", RailsVelocity);
		HazeAkCompRightRail.SetRTPCValue("Rtpc_SnowGlobe_Lake_GyroBridge_Rails_Velocity", RailsVelocity);	

		if(TorqueNormalized > 0.f && !bIsGyroMoving)
		{
			HazeAkComp.HazePostEvent(StartGyroBridgeAudioEvent);
			HazeAkCompLeftRail.HazePostEvent(StartGyroRailAudioEvent);
			HazeAkCompRightRail.HazePostEvent(StartGyroRailAudioEvent);
			bIsGyroMoving = true; 
		}

		else if(TorqueNormalized == 0.f && bIsGyroMoving)
		{
			HazeAkComp.HazePostEvent(StopGyroBridgeAudioEvent);
			HazeAkCompLeftRail.HazePostEvent(StopGyroRailAudioEvent);
			HazeAkCompRightRail.HazePostEvent(StopGyroRailAudioEvent);
			bIsGyroMoving = false; 
		}

		if (Network::IsNetworked())
		{
			if (HasControl())
			{
				if (Time::GameTimeSeconds > NextSyncTime)
				{
					NextSyncTime = Time::GameTimeSeconds + 0.5f;
					NetSendControlSideRotation(Yaw, Pitch);
				}
			}
			else
			{
				Yaw = FQuat::Slerp(Yaw, ControlYaw, 0.6f * DeltaTime);
				Pitch = FQuat::Slerp(Pitch, ControlPitch, 0.6f * DeltaTime);
			}
		}

		FVector Direction = (Yaw * Pitch).ForwardVector;

	//	System::DrawDebugLine(BasePivot.WorldLocation, BasePivot.WorldLocation + Yaw.UpVector * YawVelocity * 3000.f, FLinearColor::Blue, 0.f, 100.f);
	//	System::DrawDebugLine(BasePivot.WorldLocation, BasePivot.WorldLocation + Yaw.RightVector * PitchVelocity * 3000.f, FLinearColor::Green, 0.f, 100.f);


	//	System::DrawDebugLine(BasePivot.WorldLocation, BasePivot.WorldLocation + Direction * 4000.f, FLinearColor::Green, 0.f, 30.f);

		BasePivot.SetRelativeRotation(Yaw);
		BridgePivot.SetRelativeRotation(Pitch);
	}

	FVector GetPivotTorque(FVector ForceLocation, FVector Force, FVector PivotLocation, FVector ConstrainDirection)
	{
		FVector ToPivot = (PivotLocation - ForceLocation).GetSafeNormal();

		FVector TorqueAtPivot = Force.CrossProduct(ToPivot);

		TorqueAtPivot = TorqueAtPivot.ConstrainToDirection(ConstrainDirection);
		
		TorqueAtPivot = ActorTransform.InverseTransformVector(TorqueAtPivot);

		return TorqueAtPivot;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendControlSideRotation(FQuat InYaw, FQuat InPitch)
	{
		ControlYaw = InYaw;
		ControlPitch = InPitch;
	}

}