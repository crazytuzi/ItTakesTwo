
event void FHookReachedDestinationEventSignature(const FHitResult HitData);

enum EHookCableState
{
	Passive,
	Extending,
	Retracting,	
	Attached,
};

UCLASS(HideCategories = "Cooking ComponentReplication Tags")
class UHookCableComponent : UHazeCableComponent
{
	default bAutoActivate = true;
	default EndLocation = FVector::ZeroVector;
	default CableLength = 300.f;
	default SolverIterations = 4;
	default NumSegments = 20;
	default SetHiddenInGame(true);

	// Controls how long the retraction should take, in seconds. 
	// Will override other retraction settings if Retraction_Time > 0. 
	// We'll calculate a constant velocity based on the time. 
	float Retraction_Time = -1.f;

	// The Initial Retraction speed.
	float Retraction_ImpulseSpeed = 6000.f;		// 6000 default

	// How much the retraction should accelerate every update
	float Retraction_Acceleration = 3000.f;

	// damps the retraction speed each update. 
	// Speed = (1-LinearDamping) * Speed
	float Retraction_LinearDamping = 0.3f;	

	// Controls how far apart the particles 
	// should be from each other when fully retracted. 
	// DistanceBetweenParticles = CableLength / NumParticles
	float Retraction_CableLength = 1.f;

	// Cable Settings Retraction 
	//////////////////////////////////////////////////////////////////////////
	// Cable Settings Extension 

	// The initial speed the hook will get when it gets shot 
	float Extension_ImpulseSpeed = 8000.f;

	// The acceleration it will speed up with every tick during flight
	float Extension_Acceleration = 12000.f;

	// Physics parameter - not visuals. It will control
	// how far apart the particle are from each other
	// when the rope is extending. 
	float Extension_CableLength = 100.f;	// default == 100	

	// Cable Settings Extension
	//////////////////////////////////////////////////////////////////////////
	// Spiral Setting 

	// Which direction the particles should spiral towards  
	bool bSpiralParticlesClockwise = true;

	// More force == bigger spiral radius.
	// we'll push out the particle towards 
	// the desired locations with this force
	float SpiralForce = 60000.f;

	// How many turns the spiral should make
	// on the maximum cable length
	int SpiralTurns = 2;

	// The spiral radius is not constant over the cable length
	// We'll scale it based on a curve based on the fallOff factor
	// https://www.wolframalpha.com/input/?i=plot+x%5E2,+x+from+0+to+1
	float SpiralForceFallOff = 1.0f;

	// Experimental Spiral Settings (WORK INPROGRESS)
	bool bUseCustomSpiralSettings = false;
	float SpiralHeight = 1000.f;
	float SpiralRadius = 50.f;

	// Spiral Settings 
	//////////////////////////////////////////////////////////////////////////
	// Assets

	// Optional mesh to be used at the end of the rope
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category="HookCable")
	UStaticMesh EndMesh;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem HookEffect_Attached;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem HookEffect_Shoot;

	// Assets
	//////////////////////////////////////////////////////////////////////////
	// Transients

	UNiagaraComponent HookEffectInstance_Attached;
	UNiagaraComponent HookEffectInstance_Shoot;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHookReachedDestinationEventSignature OnTargetReached;

	UStaticMeshComponent EndMeshComponent = nullptr;
	EHookCableState CurrentState = EHookCableState::Passive;

	USceneComponent HitComp = nullptr;
	FVector TraceEnd = FVector::ZeroVector;
	FVector	TraceStart = FVector::ZeroVector;
	FVector TargetLocation_WORLD = FVector::ZeroVector;
	FVector TargetLocation_LOCAL = FVector::ZeroVector;
	FTransform ReferenceTransform = FTransform::Identity;
	float Extension_Speed = 0.f;
	float Retraction_Speed = 0.f;
	FRotator EndMeshRotation = FRotator::ZeroRotator;
	FVector EndMeshLocation = FVector::ZeroVector;

	float DistanceToAttachPoint = 0.f;

	void ResetTransients_Hook()
	{
		HitComp = nullptr;
		TraceEnd = FVector::ZeroVector;
		TraceStart = FVector::ZeroVector;
		TargetLocation_WORLD = FVector::ZeroVector;
		TargetLocation_LOCAL = FVector::ZeroVector;

		ReferenceTransform = FTransform::Identity;

		CurrentState = EHookCableState::Passive;

		Extension_Speed = 0.f;
		Retraction_Speed = 0.f;

		DistanceToAttachPoint = 0.f;
	}

	void ResetTransients_Cable()
	{
		EndLocation = FVector::ZeroVector;
	}

	void ResetTransientData() 
	{
		ResetTransients_Hook();
		ResetTransients_Cable();
	}

	// Transients
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		UpdateEndMeshTransform();

		if (CurrentState == EHookCableState::Passive)
			return;

		FVector CurrentStartPos, CurrentEndPos;
		GetEndPositions(CurrentStartPos, CurrentEndPos);

		if (CurrentState == EHookCableState::Attached)
		{
			ClampCableLength();
			return;
		}

		//////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		// @TODO: extension is currently calculated and applied
		// even when Retracting. Move it once tested properly

//		System::DrawDebugSphere(DesiredPos, 3002.f, 16.f, FLinearColor::Red);
//		System::DrawDebugSphere(CurrentEndPos, 3002.f, 16.f, FLinearColor::Blue);

		FVector DesiredPos = FVector::ZeroVector;
		if(CurrentState == EHookCableState::Extending)
			DesiredPos = GetTargetLocation();
		else if(CurrentState == EHookCableState::Retracting)
			DesiredPos = CurrentStartPos;

		const FVector CurrentEndToDesiredEnd = DesiredPos - CurrentEndPos;
		const FVector DirectionToDesiredTarget = (CurrentEndToDesiredEnd).GetSafeNormal();

		const float DeltaFromSpeed = Extension_Speed * DeltaTime;
		const float DeltaFromAcceleration = 0.5f * DeltaTime * DeltaTime * Extension_Acceleration;
		float DeltaMoveAmount = DeltaFromSpeed + DeltaFromAcceleration;

		// Constrain deltaMove to never overshoot.
		const float CurrentToDesiredDistance = CurrentEndToDesiredEnd.Size();
		DeltaMoveAmount = FMath::Clamp(DeltaMoveAmount, 0.f, CurrentToDesiredDistance);
		const FVector Extension_DeltaMove = DirectionToDesiredTarget*DeltaMoveAmount;
		const FVector NewEndPos = CurrentEndPos + Extension_DeltaMove;

//		Print("[Cable] DeltaMoveAmount: " + Extension_DeltaMove.Size(), Color = FLinearColor::White);
//		Print("[Cable] CurrentSpeed: " + CurrentSpeed, Color = FLinearColor::White);

		Extension_Speed += DeltaTime * Extension_Acceleration;

		//////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////

		if (CurrentState == EHookCableState::Extending)
		{
			FHitResult HitData;
			const FVector ExtraTracePadding = GetEndParticleForwardDirection()*5.f;
			if (RayTrace(CurrentEndPos, NewEndPos + ExtraTracePadding, HitData))
			{
				HandleAttachment(HitData);
				OnTargetReached.Broadcast(HitData);
			}
			else if (FMath::IsNearlyZero(CurrentToDesiredDistance, 1.f))
			{
				BeginRetraction();
			}
			else 
			{
				UpdateSpiralForces();
			}

		}
		else if (CurrentState == EHookCableState::Retracting)
		{
			UpdateRetraction(DeltaTime);
			if (CableLength <= Retraction_CableLength)
			{
				CompleteRetraction();
				OnTargetReached.Broadcast(FHitResult());
			}
		}

		// @TODO This should only need to be applied during 
		// ::Extending. Move it once we've tested it properly. 
		SetEndWorldLocation(NewEndPos);
	}

	void HandleAttachment(FHitResult& HitData)
	{
		Extension_Speed = 0.f;
		ResetParticleForces();
		SetAttachEndTo(HitData.GetActor(), FName(HitData.GetComponent().GetName()), HitData.BoneName);
		ReferenceTransform = GetEndTransform();
		CurrentState = EHookCableState::Attached;
		EndMeshRotation = Math::MakeRotFromX(-HitData.ImpactNormal);
		EndMeshLocation = HitData.ImpactPoint;
		PlayHookEffect_Attached(EndMeshLocation, EndMeshRotation);
	}
	
	void BeginRetraction() 
	{
		//////////////////////////////////////////////////////////////////////////
		// @TODO: might be better to move this to the capability. 
		if (CurrentState == EHookCableState::Attached)
			ResetParticleVelocities();
		//////////////////////////////////////////////////////////////////////////

		ResetParticleForces();

		FVector StartPos, EndPos;
		GetEndPositions(StartPos, EndPos);
		const float Distance = (StartPos - EndPos).Size();
		CableLength = Distance;

		// NOTE: this needs to happen after the cablelength update
		ResetTransients_Hook();

		SetAttachEndTo(nullptr, NAME_None, NAME_None);
//		EndLocation = FVector::ZeroVector;
		bAttachEnd = false;

		bEnableStiffness = false;
		bEnableCollision = false;
		SolverIterations = 1;
		CableGravityScale = 0.f;

		if(Retraction_Time > 0.f )
			Retraction_Speed = Distance / Retraction_Time;
		else 	
	 		Retraction_Speed = Retraction_ImpulseSpeed;

		CurrentState = EHookCableState::Retracting;
	}

	void UpdateRetraction(const float DeltaTime)
	{
		if (Retraction_Time > 0.f)
		{
			CableLength -= Retraction_Speed*DeltaTime;
		}
		else 
		{
			const float RetractionFromSpeed = Retraction_Speed * DeltaTime;
			const float RetractionFromAcceleration = 0.5f * DeltaTime * DeltaTime * Retraction_Acceleration;

			CableLength -= RetractionFromSpeed;
			CableLength -= RetractionFromAcceleration;

			Retraction_Speed += Retraction_Acceleration * DeltaTime;
			Retraction_Speed *= FMath::Clamp(1.f - Retraction_LinearDamping*DeltaTime, 0.f, 1.f);
		}

		const FVector DesiredPos = GetStartParticleLocation();
		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bFree == true)
			{
				const FVector CurrPos = Particles[i].Position;
				const FVector ForceDir = (DesiredPos - CurrPos).GetSafeNormal();
				Particles[i].Force = ForceDir * 1000.f;
			}
		}

		// shrink cable length faster if we are 
		// running towards a retracting cable. 
		ClampCableLength();

// 		Print("Retracting. CableLength = " + CableLength);
// 		Print("Retracting. RetractionSpeed = " + Retraction_Speed);
	}

	void ClampCableLength() 
	{
 		FVector CableStart, CableEnd;
 		GetEndPositions(CableStart, CableEnd);
 		const float MaxCableLengthDesired = (CableStart - CableEnd).Size();
		if (MaxCableLengthDesired < CableLength)
			CableLength = MaxCableLengthDesired;
		else if (CableLength < 0.f)
			CableLength = 0.f;
	}

	void CompleteRetraction() 
	{
		CableLength = Retraction_CableLength;
		CableGravityScale = 1.f;
		SetHiddenInGame(true);
		bEnableCollision = false;
		ResetParticleVelocities();
		CurrentState = EHookCableState::Passive;
	}

	void ShootHook(const FHitResult& HitData)
	{
		CurrentState = EHookCableState::Extending;

		ReferenceTransform = GetWorldTransform();

		TraceEnd = HitData.TraceEnd;
		TraceStart = HitData.TraceStart;
		const FVector TraceDirection = (TraceEnd - TraceStart).GetSafeNormal();
		TargetLocation_WORLD = HitData.bBlockingHit ? HitData.ImpactPoint : HitData.TraceEnd;
		const float ExtraHookPenetrationDistance = 5.f;
		TargetLocation_WORLD += TraceDirection*ExtraHookPenetrationDistance;

		if (HitData.bBlockingHit && HitData.GetComponent() != nullptr)
		{
			HitComp = HitData.GetComponent();
			const auto HitCompTransform = HitComp.GetWorldTransform();
			TargetLocation_LOCAL = HitCompTransform.InverseTransformPosition(HitData.ImpactPoint);
		}
		else 
		{
			HitComp = nullptr;
			TargetLocation_LOCAL = FVector::ZeroVector;
		}
		
		Extension_Speed = Extension_ImpulseSpeed;

		ResetParticleVelocities();
 		SetHiddenInGame(false);
		bEnableCollision = false;

		CableLength = Extension_CableLength;
		bEnableStiffness = false;		// true
		SolverIterations = 2;	// 4

		SetAttachEndTo(GetOwner(), FName(GetName()), NAME_None);
		bAttachEnd = true;
		SetEndWorldLocation(GetWorldLocation());

		PlayHookEffect_Shoot(GetEndParticleLocation(), GetWorldRotation());
	}

	UFUNCTION(BlueprintOverride)
	bool GetEndPositions(FVector& OutStartPosition, FVector& OutEndPosition) const
	{
		OutStartPosition = GetWorldLocation();
		OutEndPosition = GetEndWorldLocation();
		return true;
	}

	FVector GetTargetLocation() const
	{
		if (HitComp != nullptr)
			return HitComp.GetWorldTransform().TransformPosition(TargetLocation_LOCAL);
		return TargetLocation_WORLD;
	}

	void SetEndWorldLocation(FVector InWorldLocation) 
	{
		EndLocation = GetEndTransform().InverseTransformPosition(InWorldLocation);
	}

	FVector GetEndWorldLocation() const
	{
		return GetEndTransform().TransformPosition(EndLocation);
	}

	FTransform GetEndTransform() const
	{
		USceneComponent EndComponent = GetAttachedComponent();
		if (EndComponent != nullptr && EndComponent != this)
		{
			if (GetAttachEndToSocketName() != NAME_None)
				return EndComponent.GetSocketTransform(GetAttachEndToSocketName());
			else
				return EndComponent.GetWorldTransform();
		}

		ensure(!ReferenceTransform.GetTranslation().IsZero());

		return ReferenceTransform;
	}

	bool RayTrace(const FVector& From, const FVector& To, FHitResult& OutHit) const
	{
		if(GetOwner() == nullptr)
			return false;

		if(GetOwner().GetAttachParentActor() == nullptr)
			return false;
			
		TArray<AActor> IgnoreActors;
		GetOwner().GetAttachParentActor().GetAttachedActors(IgnoreActors);
		IgnoreActors.Add(GetOwner().GetAttachParentActor());
		IgnoreActors.Add(GetOwner());

		return System::SphereTraceSingle(
			From,
			To,
			CableWidth,
			ETraceTypeQuery::WeaponTrace,
			false,
			IgnoreActors,
			EDrawDebugTrace::None,
			OutHit,
			true
		);

// 		return System::LineTraceSingle(
// 			From,
// 			To,
// 			ETraceTypeQuery::WeaponTrace,
// 			false,
// 			IgnoreActors,
// 			EDrawDebugTrace::None,
// 			OutHit,
// 			true
// 		);
	}

	UFUNCTION(BlueprintCallable, Category="HookCableMesh")
	UStaticMeshComponent GetOrCreateEndMeshComponent()
	{
		if (EndMeshComponent == nullptr && EndMesh != nullptr)
		{
			AHazeActor HazeOwner = Cast<AHazeActor>(GetOwner());
			UActorComponent PotentialStaticMeshComp = HazeOwner.CreateComponent(UStaticMeshComponent::StaticClass(), n"HookShotEndMesh");
			EndMeshComponent = Cast<UStaticMeshComponent>(PotentialStaticMeshComp);
			EndMeshComponent.SetStaticMesh(EndMesh);
		}
		return EndMeshComponent;
	}

	void UpdateEndMeshTransform() 
	{
		UStaticMeshComponent EndMeshComp = GetOrCreateEndMeshComponent();
		if (EndMeshComp == nullptr)
			return;

		if (CurrentState != EHookCableState::Attached)
		{
			// The other states will set the rotation were it's needed
			if (CurrentState == EHookCableState::Extending || CurrentState == EHookCableState::Retracting)
			{
				EndMeshRotation = Math::MakeRotFromX(GetEndParticleForwardDirection());
				EndMeshLocation = GetEndParticleLocation();
			}
			else if (CurrentState == EHookCableState::Passive)
			{
				EndMeshRotation = GetWorldRotation();
				EndMeshLocation = GetWorldLocation();
			}
		}

		EndMeshComp.SetWorldLocation(EndMeshLocation);
		EndMeshComp.SetWorldRotation(EndMeshRotation);
	}

	void UpdateSpiralForces() 
	{
		const float InitialDistance = (GetTargetLocation() - ReferenceTransform.GetLocation()).Size();
		const float CurrentDistance = (GetTargetLocation() - GetEndParticleLocation()).Size();
		const float TravelFraction = 1.f - FMath::Clamp(CurrentDistance / InitialDistance, 0.f, 1.f);

		float ForceScaler = 1.f;
		if (SpiralForceFallOff != 0.f)
			ForceScaler = FMath::Pow(TravelFraction, SpiralForceFallOff);

		if (FMath::IsNearlyEqual(TravelFraction, 1.f))
			return;

// 		Print("Spiral Force Scaler: " + ForceScaler);

   		const float ScaledSpiralForce = SpiralForce * ForceScaler;

		int PointsPerTurn = NumSegments / SpiralTurns;		
		float Pitch = SpiralHeight / PointsPerTurn;
		float StepSize_Angular = 360.f / PointsPerTurn;
		StepSize_Angular *= bSpiralParticlesClockwise ? -1 : 1;
		float StepSize_Pitch = Pitch / PointsPerTurn;

		FRotator CompRotation = GetWorldRotation();
		FVector CompLocation = GetWorldLocation();
		FVector RopeDirection = Particles.Last().Position - Particles[0].Position;
		RopeDirection.Normalize();
		CompRotation = Math::MakeRotFromZ(RopeDirection);
		CompLocation = Particles[0].Position;

		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bFree)
			{
				const float RadStepSize = FMath::DegreesToRadians(i*StepSize_Angular);
				const float OffsetX = FMath::Sin(RadStepSize);
				const float OffsetY = FMath::Cos(RadStepSize);

				FVector DesiredParticleLocation = CompLocation;
				if (bUseCustomSpiralSettings)
				{
					const FVector Offset = FVector(OffsetX*SpiralRadius, OffsetY*SpiralRadius, i*StepSize_Pitch);
					const FVector Offset_Rotated = CompRotation.RotateVector(Offset);
					DesiredParticleLocation += Offset_Rotated;
				}
				else 
				{
					const FVector Offset = FVector(OffsetX*SpiralRadius, OffsetY*SpiralRadius, 0.f);
					const FVector Offset_Rotated = CompRotation.RotateVector(Offset);
					const FVector ParticleOffsetFromRoot = RopeDirection * (Particles[i].Position - CompLocation).Size();
					DesiredParticleLocation += Offset_Rotated;
					DesiredParticleLocation += ParticleOffsetFromRoot;
				}

				const FVector DeltaSpiralTranslation = (DesiredParticleLocation - Particles[i].Position);
				const FVector TowardsDesiredNormalized = DeltaSpiralTranslation.GetSafeNormal();

				Particles[i].Force = TowardsDesiredNormalized * ScaledSpiralForce;

// 				const FVector DebugStart = Particles[i].Position;
// 				const FVector DebugEnd = DebugStart + TowardsDesiredNormalized * 100.f;
// 				System::DrawDebugLine(DebugStart, DebugEnd, FLinearColor::White, 0.f , 3.f);
// 				System::DrawDebugPoint(DesiredParticleLocation, 10.f, FLinearColor::Red, 0.f);
			}

// 			FColor DebugColor = Particles[i].bFree ? FColor::Yellow : FColor::Blue;
// 			DrawDebugSphere(GetWorld(), Particles[i].Position, 10.f, 10.f, DebugColor, 0.f);
		}
	}

	void PlayHookEffect_Attached(FVector WorldPos, FRotator WorldRot = FRotator::ZeroRotator)
	{
		HookEffectInstance_Attached = Niagara::SpawnSystemAtLocation(
			HookEffect_Attached,
			WorldPos, 
			WorldRot
		);
	}

	void PlayHookEffect_Shoot(FVector WorldPos, FRotator WorldRot = FRotator::ZeroRotator)
	{
		HookEffectInstance_Shoot= Niagara::SpawnSystemAtLocation(
			HookEffect_Shoot,
			WorldPos, 
			WorldRot
		);
	}

}
