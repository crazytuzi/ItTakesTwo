import Vino.Movement.Swinging.SwingPointComponent;

class ASwingPointBehaviourActor : AHazeActor
{
	TPerPlayer<AHazePlayerCharacter> Players;

	UPROPERTY()
	AHazeActor SwingPointActor;

	USwingPointComponent SwingPointComp;

	UPROPERTY(Category = "Movement Behaviour")
	float BounceAmount = 50.f;
	
	UPROPERTY(Category = "Movement Behaviour")
	float RotationMultiplier = 0.4f;

	UPROPERTY(Category = "Movement Behaviour")
	float RotationAccelerationTime = 2.8f;

	float RotationAccelerationCorrection;

	float RopeLength;

	FHazeAcceleratedFloat AccelZ;
	FHazeAcceleratedQuat AccelQuat;

	FVector StartLoc;
	FRotator StartRot;
	FVector BounceLocation;
	FQuat StartQuat;

	TPerPlayer<bool> bFirstSwings;

	float TotalDistMultiplier;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SwingPointActor != nullptr)
		{
			SwingPointComp = USwingPointComponent::Get(SwingPointActor);
			RopeLength = SwingPointComp.RopeLength;

			SwingPointComp.OnSwingPointAttached.AddUFunction(this, n"PlayerAttach");
			SwingPointComp.OnSwingPointDetached.AddUFunction(this, n"PlayerDetach");

			SwingPointComp.OnSwingPointEnabled.AddUFunction(this, n"EnableFromSwingpoint");
			SwingPointComp.OnSwingPointDisabled.AddUFunction(this, n"DisableFromSwingpoint");
		}
		else
		{
			PrintError("" + Name + " does not reference a Swing Point");
		}

		StartLoc = ActorLocation;
		StartRot = ActorRotation;

		StartQuat = ActorRotation.Quaternion();
		AccelQuat.SnapTo(StartQuat);

		AccelZ.SnapTo(0.f);

		TotalDistMultiplier = (SwingPointActor.ActorLocation - ActorLocation).Size() / 230.f;

		RotationAccelerationCorrection = RotationAccelerationTime * 1.3f;
	}

	UFUNCTION()
	void PlayerAttach(AHazePlayerCharacter Player)
	{
		bFirstSwings[Player] = true;

		if (Player == Game::May)
			Players[0] = Player;
		else
			Players[1] = Player;
	}

	UFUNCTION()
	void PlayerDetach(AHazePlayerCharacter Player)
	{
		bFirstSwings[Player] = false;

		if (Player == Game::May)
			Players[0] = nullptr;
		else
			Players[1] = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnableFromSwingpoint()
	{
		EnableActor(SwingPointComp);
	}

	UFUNCTION(NotBlueprintCallable)
	private void DisableFromSwingpoint()
	{
		DisableActor(SwingPointComp);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Players[0] != nullptr || Players[1] != nullptr)
		{
			FVector AverageDir;
			int Divider = 0;

			for (AHazePlayerCharacter Player : Players)
			{
				if (Player == nullptr)
					continue;

				FVector From = ActorLocation + (-FVector::UpVector * (Player.ActorLocation - ActorLocation).Size());
				FVector ToDirection = Player.ActorLocation - From;
				float DistanceTo = ToDirection.Size() * RotationMultiplier;
				ToDirection.Normalize();
				FVector To = From + (ToDirection * DistanceTo);

				// System::DrawDebugSphere(From, 20.f, 12, FLinearColor::Green);
				// System::DrawDebugSphere(To, 20.f, 12, FLinearColor::Blue);

				FVector Dir = ActorLocation - To;
				Dir.Normalize();
				
				if (bFirstSwings[Player])
				{
					float Dot = FVector::UpVector.DotProduct(Dir);

					if (Dot >= 0.995f)
						bFirstSwings[Player] = false;
					else
						continue;
				}

				Divider++;
				AverageDir += Dir * RotationMultiplier;
			}

			if (Divider > 1)
				AverageDir /= Divider;
			
			AverageDir *= RotationMultiplier;

			AccelQuat.AccelerateTo(GetPlayersAttachedQuaternion(AverageDir), (RotationAccelerationTime * RotationMultiplier) * TotalDistMultiplier, DeltaTime);
			BounceBehaviour(DeltaTime);
		}
		else
		{
			ReturnOriginBehaviour(DeltaTime);
		}
		
		//Accelerating twice is kinda a weird solution, but works pretty well for now. If issues, look into clamps and POW
		AccelQuat.AccelerateTo(StartQuat, (RotationAccelerationCorrection * RotationMultiplier) * TotalDistMultiplier, DeltaTime);

		SetActorLocationAndRotation(BounceLocation, AccelQuat.Value);
	}

	FQuat GetPlayersAttachedQuaternion(FVector InDirection)
	{
		FQuat Quat = Math::MakeQuatFromZ(InDirection);
		FQuat A;
		FQuat B;

		Quat.ToSwingTwist(FVector::UpVector, A, B);
		
		return A;
	}

	void BounceBehaviour(float DeltaTime)
	{
		float DownAverage = 0.f;
		float FinalDown = 0.f;
		float ZDownPercent = 0.f;

		int Divider = 0;
		
		for (AHazePlayerCharacter Player : Players)
		{
			if (Player == nullptr)
				continue;

			// FVector Dir = ActorLocation - Player.ActorLocation;
			// Dir.Normalize();

			// float Dot = FVector::UpVector.DotProduct(Dir);

			// DownAverage += BounceAmount * Dot;

			if (bFirstSwings[Player])
				continue;

			float ZDist = StartLoc.Z - Player.ActorLocation.Z;
			
			if (ZDist > 0.f)
			{
				Divider++;
				ZDownPercent = 1 - (ZDist / RopeLength);
				FinalDown = ZDownPercent * BounceAmount;
				DownAverage += FinalDown;
			}
		}

		if (Divider > 1)
			DownAverage /= Divider;
		
		AccelZ.AccelerateTo(DownAverage, 1.2f, DeltaTime);

		FVector OffsetLoc = FVector(0.f, 0.f, AccelZ.Value);
		BounceLocation = StartLoc + OffsetLoc;
	}

	void ReturnOriginBehaviour(float DeltaTime)
	{
		AccelZ.AccelerateTo(0.f, 2.8f, DeltaTime);
		FVector OffsetLoc = FVector(0.f, 0.f, AccelZ.Value);
		BounceLocation = StartLoc + OffsetLoc;
	}
}