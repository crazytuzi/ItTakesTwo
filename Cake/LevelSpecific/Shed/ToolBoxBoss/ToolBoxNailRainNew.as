import Cake.LevelSpecific.Shed.ToolBoxBoss.PlayerNailRainedComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

const FStatID STAT_NailMovementUpdate(n"NailMovementUpdate");
const FStatID STAT_NailTracing(n"NailTracing");
const FStatID STAT_NailDecalMaterial(n"NailDecalMaterial");
const FStatID STAT_NailDecalUpdate(n"NailDecalUpdate");

class UToolBoxRainGroupVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UToolBoxRainGroupVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
    	AToolBoxRainControllerNew Controller = FindRootController(Component.Owner);
    	if (Controller == nullptr)
    		return;

    	for(auto Group : Controller.Groups)
    	{
			if (Group != nullptr)
				DrawGroupBoundary(Group);
    	}
    }

    void DrawGroupBoundary(AToolBoxRainGroupNew Group)
    {
    	// Already drawn this frame :)
    	if (Group.VisComp.LastDrawnFrameNum == GFrameNumber)
    		return;

    	for(int i=1; i<Group.VisComp.ConvexHull.Num(); ++i)
    	{
    		FVector Offset = FVector::UpVector * 50.f;
    		FVector LastPoint = Group.VisComp.ConvexHull[i - 1];
    		FVector Point = Group.VisComp.ConvexHull[i];

    		DrawDashedLine(LastPoint + Offset, Point + Offset, FLinearColor::Red);
    	}

    	Group.VisComp.LastDrawnFrameNum = GFrameNumber;
    }
}

// This component is only used for drawing the groups in editor, not to be used in gameplay!
// But this component on anything, if it is selected, it will draw out the groups it belongs to or owns
class UToolBoxRainGroupVisualizerComponent : UActorComponent
{
	TArray<FVector> ConvexHull;
	uint LastDrawnFrameNum = 0;

	void BuildConvexHull(AToolBoxRainGroupNew Group)
	{
		ConvexHull.Empty();

		// No nails in group...
		if (Group.Nails.Num() < 3)
			return;

		/* Calculate and draw the convex hull around all nails! */
		// Start With the left-most nail...
		AActor LeftMost = Group.Nails[0];
		for(auto Nail : Group.Nails)
			LeftMost = SelectLeftMost(LeftMost, Nail);

		ConvexHull.Add(LeftMost.ActorLocation);

		/* Then iterate through all nails, always finding the nail that MOST counter-clockwise from the current nail.
			After its found, draw a line between the current and next nail.
			Continue until the next nail is the one we started with. */

		// We want a separate list of visited nails, so we cant use the same nail more than once
		TArray<AActor> VisitedNails;

		AActor CurrentNail = LeftMost;
		AActor NextNail = nullptr;
		while(NextNail != LeftMost)
		{
			// Find most counter-clockwise
			for(auto Nail : Group.Nails)
			{
				if (VisitedNails.Contains(Nail))
					continue;

				if (Nail == CurrentNail)
					continue;

				if (NextNail == nullptr)
				{
					NextNail = Nail;
					continue;
				}

				NextNail = SelectCounterClockwise(CurrentNail, NextNail, Nail);
			}

			FVector Offset = FVector::UpVector * 50.f;

			// And iterate to it
			ConvexHull.Add(NextNail.ActorLocation);
			CurrentNail = NextNail;

			// We dont wanna visit this nail again..
			VisitedNails.Add(NextNail);
		}
    }

	// Select the one with smallest X :) Arbitrary but it works
	AActor SelectLeftMost(AActor First, AActor Second)
	{
		FVector A = First.ActorLocation;
		FVector B = Second.ActorLocation;

		return A.X < B.X ? First : Second;
	}

	AActor SelectCounterClockwise(AActor From, AActor First, AActor Second)
	{
		// Make two lines, in-between the start-first and start-second
		// If we cross those lines, the result either point upwards or downwards
		// If it points upwards, first is to the left of second
		FVector A = First.ActorLocation - From.ActorLocation;
		FVector B = Second.ActorLocation - From.ActorLocation;
		A = A.ConstrainToPlane(FVector::UpVector);
		B = B.ConstrainToPlane(FVector::UpVector);

		FVector Cross = A.CrossProduct(B);
		return Cross.Z > 0.f ? First : Second;
	}
}

class AToolBoxRainNailNew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent)
	UToolBoxRainGroupVisualizerComponent VisComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent Decal;
	default Decal.RelativeRotation = FRotator(90.f, 0.f, 0.f);

	UPROPERTY(Category="Nail", EditConst, BlueprintReadOnly)
	AToolBoxRainGroupNew OwningGroup;

	UPROPERTY(Category="Nail")
	float FallSpeed = 19000.f;

	UPROPERTY(Category="Nail")
	float MaxMissFallTime = 1.f;

	UPROPERTY(Category="Nail", EditInstanceOnly)
	float TraceHeightMax = 20.f;

	UPROPERTY(Category="Nail", EditInstanceOnly)
	float TraceHeightMin = -150.f;

	UPROPERTY(Category="Nail", EditConst)
	float ShowDecalTime = 2.f;

	UPROPERTY(Category="Nail", EditConst)
	float ShowWarningTime = 1.f;

	UPROPERTY(Category="Nail", EditConst)
	float GroundSearchDistance = 50000.f;

	UPROPERTY(Category="Nail", EditConst)
	float LandPenetrateDistanceMin = 50.f;

	UPROPERTY(Category="Nail", EditConst)
	float LandPenetrateDistanceMax = 80.f;

	UPROPERTY(Category="Nail", EditConst)
	float DecayFadePercent = 0.5f;

	UPROPERTY(Category="Nail", EditConst)
	float DecaySinkOffset = 250.f;

	UPROPERTY(Category="Nail", EditConst)
	float DecayDuration = 1.f;

	// Used when tracing for ground-hits
	UPROPERTY(Category="Nail", EditConst)
	TArray<EObjectTypeQuery> GroundTypes;
	default GroundTypes.Add(EObjectTypeQuery::WorldStatic);
	default GroundTypes.Add(EObjectTypeQuery::WorldDynamic);

	// Nail origin, used to revert back to when searching for new ground
	FTransform OriginRelativeTransform;

	// Random rotations of the nail
	FQuat NailRandomRotation;

	// Ground origin
	FTransform GroundRelativeTransform;
	UPrimitiveComponent GroundComponent;
	FHitResult GroundHit;

	bool bIsActive = true;
	UMaterialInstanceDynamic DecalMaterial;

	AHazePlayerCharacter HitPlayer = nullptr;
	AHazePlayerCharacter RequestHitPlayer = nullptr;
	bool bHasHit = false;
	float DecayTimer = DecayDuration;

	// Used to animate the falling, when reaching 0, we should have hit the ground (if we have a ground)
	float FallTime = 0.f;

	// We dont wanna start decaying until both sides have hit the ground
	int NetHitCounter = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto Controller = FindRootController(this);
		if (Controller != nullptr)
			Controller.UpdateGroups();
	}

	void UpdateNail()
	{
		OriginRelativeTransform = Root.RelativeTransform;

		FHitResult Hit = FindCurrentGroundAtOrigin();
		if (Hit.bBlockingHit)
			Decal.WorldTransform = FTransform(Math::MakeQuatFromX(Hit.Normal), Hit.Location);
		else
			Decal.RelativeTransform = FTransform();
	}

	UFUNCTION(BlueprintPure)
	FTransform GetOriginWorldTransform() property
	{
		if (OwningGroup != nullptr)
			return OriginRelativeTransform * OwningGroup.ActorTransform;
		else
			return OriginRelativeTransform;
	}

	UFUNCTION(BlueprintPure)
	FTransform GetGroundWorldTransform() property
	{
		if (GroundComponent != nullptr)
			return GroundRelativeTransform * GroundComponent.WorldTransform;
		else
			return GroundRelativeTransform;
	}

	// Returns where we _should_ be during the falling animation
	// Just based on the falltime and attachment
	UFUNCTION(BlueprintPure)
	FTransform GetCurrentFallingTransform() property
	{
		FTransform RootTransform;

		if (GroundComponent != nullptr)
			RootTransform = GetGroundWorldTransform();
		else
			RootTransform = GetOriginWorldTransform();

		// Offset upwards for falling
		FTransform FallTransform;
		FallTransform.Location = RootTransform.Location + FVector::UpVector * FallSpeed * FallTime;
		FallTransform.Rotation = NailRandomRotation;

		return FallTransform;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Add a random rotation to our attachment point
		NailRandomRotation = FQuat(FVector::UpVector, FMath::RandRange(0.f, TAU)) * FQuat(FVector::RightVector, FMath::RandRange(-0.05f, 0.05f));

		// Set the origin again, just in case it wasnt set in constructionscript
		OriginRelativeTransform = Root.RelativeTransform;

		// Make the decal material
		DecalMaterial = Material::CreateDynamicMaterialInstance(Decal.DecalMaterial);
		Decal.DecalMaterial = DecalMaterial;

		// The mesh is only for the editor, from now on all the visuals are in the groups' instanced mesh
		Mesh.DestroyComponent(Mesh);
		Mesh = nullptr;

		// Manually deactivate the nail for now...
		bIsActive = false;
		DisableActor(this);
	}

	FHitResult FindCurrentGroundAtOrigin()
	{
		FVector OriginLocation = OriginWorldTransform.Location;

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		Trace.IgnoreActor(Game::GetCody());
		Trace.IgnoreActor(Game::GetMay());
		Trace.From = OriginLocation + FVector::UpVector * TraceHeightMax;
		Trace.To = OriginLocation + FVector::UpVector * TraceHeightMin;

		FHazeHitResult Hit;
		Trace.Trace(Hit);

		return Hit.FHitResult;
	}

	void ActivateNail(float InFallTime)
	{
		if (bIsActive)
			return;

		bIsActive = true;
		bHasHit = false;
		HitPlayer = nullptr;
		NetHitCounter = 0;
		EnableActor(this);

		OwningGroup.HandleNailActivated();

		// Every time we activate, we want to re-search if there's floor under us
		// Since the trace is unreliable during beginplay (streaming)
		FHitResult Hit = FindCurrentGroundAtOrigin();
		if (Hit.bBlockingHit)
		{
			GroundHit = Hit;

			// Get our relative grounded location
			GroundComponent = Hit.Component;
			GroundRelativeTransform = FTransform(Math::MakeQuatFromZ(Hit.Normal), Hit.Location);
			GroundRelativeTransform = GroundRelativeTransform.GetRelativeTransform(GroundComponent.WorldTransform);

			// Update the decal
			Decal.WorldTransform = FTransform(Math::MakeQuatFromX(Hit.Normal), Hit.Location);
			Decal.AttachToComponent(GroundComponent, NAME_None, EAttachmentRule::KeepWorld);
			Decal.SetHiddenInGame(false);
		}
		else
		{
			GroundRelativeTransform = ActorTransform;
			Decal.SetHiddenInGame(true);
		}
			
		FallTime = InFallTime;
		AddActorWorldOffset(FVector::UpVector * FallTime * FallSpeed);

		// Move to where we should be
		ActorTransform = GetCurrentFallingTransform();

		OnActivated();
	}

	void DeactivateNail()
	{
		if (!bIsActive)
			return;

		// Make sure all attached actors becomes detached...
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false);
		for(auto Attached : AttachedActors)
		{
			Attached.DetachRootComponentFromParent(true);
		}

		// Then detach the nail itself
		DetachRootComponentFromParent();

		// If we deactivated without landing, tell our group
		if (!bHasHit)
			OwningGroup.HandleNailLanded();

		OwningGroup.HandleNailDeactivated();

		// Deactivate...
		bIsActive = false;
		DisableActor(this);

		OnDeactivated();

		// If a player is still attached, make sure to tell them we're done
		if (HitPlayer != nullptr)
		{
			auto NailRainedComp = UPlayerNailRainedComponent::Get(HitPlayer);
			if (NailRainedComp != nullptr)
			{
				NailRainedComp.HitNail = nullptr;
			}
		}

		HitPlayer = nullptr;

		// Reset grounded stuff
		GroundComponent = nullptr;
	}

	void UpdateMovement(FTransform& Transform, float DeltaTime)
	{
#if TEST
		FScopeCycleCounter UpdateMovementCounter(STAT_NailMovementUpdate);
#endif

		if (bHasHit)
		{
			bool bShouldDecay = true;

			// In network, we have to wait for both sides to register a ground hit before decaying
			// Otherwise one side might hit a player while the other one has decayed already..
			if (Network::IsNetworked())
				bShouldDecay = (NetHitCounter == 2);

			if (bShouldDecay && HitPlayer == nullptr && RequestHitPlayer == nullptr)
			{
				DecayTimer -= DeltaTime;

				// Fade out the nail during the end of the decay
				if (DecayTimer / DecayDuration < DecayFadePercent)
				{
					float FadePercent = (DecayTimer / DecayDuration) / DecayFadePercent; 
					if (DecalMaterial != nullptr)
					{
						DecalMaterial.SetScalarParameterValue(n"Time", FadePercent);
						DecalMaterial.SetScalarParameterValue(n"DangerClose", FadePercent);
					}

					AddActorWorldOffset(FVector::UpVector * -DecaySinkOffset * DeltaTime);
				}

				if (DecayTimer < 0.f)
					DeactivateNail();
			}

			Transform = ActorTransform;
		}
		else
		{
			FVector Loc = GetCurrentFallingTransform().Location;
			FVector MoveDelta = FVector::UpVector * -FallSpeed * DeltaTime;

			OnFalling(FallTime);

			// Line trace for hits only when actually close to where we're going
			if (FallTime < 0.5f && HitPlayer == nullptr)
			{
				TArray<UPrimitiveComponent> ComponentsToTrace;

				ComponentsToTrace.Add(Game::GetMay().CapsuleComponent);
				ComponentsToTrace.Add(Game::GetCody().CapsuleComponent);

				FHazeTraceParams Trace;
				Trace.SetToSphere(80.f);
				Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
				Trace.From = Loc;
				Trace.To = Loc + MoveDelta;

				FHazeHitResult Hit;
				Trace.ExclusiveTrace(ComponentsToTrace, Hit);
				if (Hit.bBlockingHit)
				{
					HandleBlockingHit(Hit.FHitResult);
				}
			}

			if (DecalMaterial != nullptr)
			{
#if TEST
				FScopeCycleCounter DecalCounter(STAT_NailDecalMaterial);
#endif
				// Update decal material based on how much time is left until impact
				DecalMaterial.SetScalarParameterValue(n"Time", Math::Saturate(1.f - (FallTime / ShowDecalTime)));
				DecalMaterial.SetScalarParameterValue(n"DangerClose", FallTime < ShowWarningTime ? 1.f : 0.f);
			}

			FallTime -= DeltaTime;

			// Hitting ground!
			if (GroundComponent != nullptr && FallTime <= 0.f)
				HitGround();

			// We've clearly missed our target, 
			if (FallTime < -MaxMissFallTime)
				DeactivateNail();

			Transform = GetCurrentFallingTransform();
		}

		if (!bHasHit)
			Transform.Scale3D = FVector(1.f, 1.f, 4.f);

		ActorTransform = Transform;
		ActorScale3D = FVector::OneVector;
	}

	void HandleBlockingHit(FHitResult Hit)
	{
		auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		if (!CanPlayerBeDamaged(Player))
			return;

		if (HasControl())
			NetHitPlayer(Player);
		else
			NetRequestHitPlayer(Player);
	}

	UFUNCTION(NetFunction)
	void NetRequestHitPlayer(AHazePlayerCharacter Player)
	{
		if (RequestHitPlayer != nullptr || HitPlayer != nullptr)
			return;

		RequestHitPlayer = Player;

		if (!HasControl())
			return;

		NetHitPlayer(Player);
	}

	UFUNCTION(NetFunction)
	void NetHitPlayer(AHazePlayerCharacter Player)
	{
		auto NailRainedComp = UPlayerNailRainedComponent::Get(Player);

		// If we hit a ground, snap back up to surface level in case we have started decaying
		// due to delays in network messages
		if (GroundComponent != nullptr)
		{
			ActorRelativeTransform = GroundRelativeTransform;
			AttachToComponent(GroundComponent, AttachmentRule = EAttachmentRule::KeepRelative);
		}

		if (NailRainedComp.HitNail == nullptr)
		{
			HitPlayer = Player;
			NailRainedComp.HitNail = this;

			OnPlayerImpact(Player);
		}

		RequestHitPlayer = nullptr;
	}

	void HitGround()
	{
		NetRegisterGroundHit();

		FallTime = 0.f;
		ActorTransform = GetCurrentFallingTransform();

		// If we didn't hit the player, penetrate into the ground a bit
		if (HitPlayer == nullptr)
		{
			float PenetrateDepth = FMath::RandRange(LandPenetrateDistanceMin, LandPenetrateDistanceMax);
			AddActorWorldOffset(FVector::UpVector * -PenetrateDepth);
		}
		else
		{
			auto NailRainedComp = UPlayerNailRainedComponent::Get(HitPlayer);
			NailRainedComp.GroundHit = GroundHit;
		}

		AttachRootComponentTo(GroundComponent, AttachLocationType = EAttachLocation::KeepWorldPosition);

		bHasHit = true;
		DecayTimer = DecayDuration;

		OnImpact(GroundHit);
	}

	UFUNCTION(NetFunction)
	void NetRegisterGroundHit()
	{
		NetHitCounter++;
	}

	FHitResult FindCurrentFallHit()
	{
		if (GroundComponent == nullptr)
			return FHitResult();

		FVector TraceDelta = FVector::UpVector * -GroundSearchDistance;
		FHazeHitResult Hit;
		GroundComponent.LineTraceAtComponent(ActorLocation + FVector::UpVector * 50.f, ActorLocation + TraceDelta, Hit);

		return Hit.FHitResult;
	}

	UFUNCTION(BlueprintEvent)
	void OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void OnFalling(float PredictedTimeToHit) {}

	UFUNCTION(BlueprintEvent)
	void OnImpact(FHitResult Where) {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerImpact(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnDeactivated() {}
}

class AToolBoxRainGroupNew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UToolBoxRainGroupVisualizerComponent VisComp;

	UPROPERTY(DefaultComponent)
	UInstancedStaticMeshComponent InstanceMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(NotEditable)
	TArray<AToolBoxRainNailNew> Nails;

	UPROPERTY(Category = "Nail Group")
	float FallTime = 2.f;

	UPROPERTY(Category = "Nail Group")
	float NailInterval = 0.2f;

	UPROPERTY(Category = "Nail Group")
	float NailIntervalVariance = 0.08f;

	int NailsInAir = 0;
	int NailsActive = 0;
	TArray<FTransform> NailTransforms;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto Controller = FindRootController(this);
		if (Controller != nullptr)
			Controller.UpdateGroups();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Nail : Nails)
		{
			NailTransforms.Add(Nail.ActorTransform);
			InstanceMesh.AddInstanceWorldSpace(FTransform());
		}

		// By default, disable everything
		HandleNailDeactivated();
	}

	UFUNCTION(CallInEditor)
	void UpdateGroup()
	{
		Nails.Empty();

		TArray<AActor> Children;
		GetAttachedActors(Children, false);
		for(auto Actor : Children)
		{
			auto Nail = Cast<AToolBoxRainNailNew>(Actor);
			if (Nail != nullptr)
				Nails.Add(Nail);

			Nail.OwningGroup = this;
			Nail.UpdateNail();
		}

		VisComp.BuildConvexHull(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(int i=0; i<Nails.Num(); ++i)
		{
			if (Nails[i].bIsActive)
				Nails[i].UpdateMovement(NailTransforms[i], DeltaTime);

			// If we hit a player we want to move, BUT the nail gets replaced with another
			//	actor for animation, so hide this one :)
			if (!Nails[i].bIsActive || Nails[i].HitPlayer != nullptr)
			{
				// Banking on origin being off-screen
				NailTransforms[i].Scale3D = FVector::ZeroVector;
				continue;
			}
		}

		InstanceMesh.BatchUpdateInstancesTransforms(0, NailTransforms, true, true, true);
	}

	void LaunchGroup()
	{
		if (!HasControl())
			return;

		// Compile a list of nails to be launched
		TArray<int> LaunchIndices;
		TArray<float> LaunchTimes;

		for(int i=0; i<Nails.Num(); ++i)
		{
			if (Nails[i].bIsActive)
				continue;

			LaunchIndices.Add(i);
			LaunchTimes.Add(FallTime + NailInterval * i + NailIntervalVariance * FMath::RandRange(-0.5f, 0.5f));
		}

		NetLaunchGroup(LaunchIndices, LaunchTimes);
	}

	UFUNCTION(NetFunction)
	void NetLaunchGroup(TArray<int> LaunchIndices, TArray<float> LaunchTimes)
	{
		for(int i=0; i<LaunchIndices.Num(); ++i)
		{
			int Index = LaunchIndices[i];
			float LaunchTime = LaunchTimes[i];

			// Can happen on remote side
			if (Nails[Index].bIsActive)
				Nails[Index].DeactivateNail();

			Nails[Index].ActivateNail(LaunchTimes[i]);
			NailsInAir++;
		}

		if (NailsInAir > 0)
			OnGroupLaunched();
	}

	void HandleNailLanded()
	{
		NailsInAir--;
		if (NailsInAir <= 0)
			OnGroupFinished();
	}

	void HandleNailActivated()
	{
		if (NailsActive == 0)
			EnableActor(this);

		NailsActive++;
	}

	void HandleNailDeactivated()
	{
		NailsActive = FMath::Max(NailsActive - 1, 0);

		if (NailsActive == 0)
		{	
			HazeAkComp.HazeStopEvent();
			DisableActor(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnGroupLaunched() {}

	UFUNCTION(BlueprintEvent)
	void OnGroupFinished() {}

	UFUNCTION(BlueprintEvent)
	void OnGroupDisabled() {}

	// We only want each group to only play ONE sound per frame, to avoid stuttering
	uint LastSoundFrameNum = 0;

	UFUNCTION(BlueprintPure)
	bool GroupCanPlaySoundsThisFrame()
	{
		return LastSoundFrameNum != GFrameNumber;
	}

	UFUNCTION()
	void HandleSoundPlayed()
	{
		LastSoundFrameNum = GFrameNumber;
	}
}

class AToolBoxRainControllerNew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UToolBoxRainGroupVisualizerComponent VisComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AToolBoxRainGroupNew> Groups;

	int LastGroupIndex = -1;

	UFUNCTION(CallInEditor)
	void UpdateGroups()
	{
		Groups.Empty();

		TArray<AActor> Children;
		GetAttachedActors(Children, false);

		for(auto Actor : Children)
		{
			auto NailGroup = Cast<AToolBoxRainGroupNew>(Actor);
			if (NailGroup != nullptr)
			{
				Groups.Add(NailGroup);
				NailGroup.UpdateGroup();
			}
		}
	}

	UFUNCTION(DevFunction)
	void LaunchRandomGroup()
	{
		if (!HasControl())
			return;

		if (Groups.Num() == 0)
			return;

		int Index = FMath::RandRange(0, Groups.Num() - 1);

		// Keep selecting groups until we find a group thats _not_ the last one we launched
		if (Groups.Num() > 1)
		{
			while(Index == LastGroupIndex)
				Index = FMath::RandRange(0, Groups.Num() - 1);
		}

		Groups[Index].LaunchGroup();
		LastGroupIndex = Index;
	}

	UFUNCTION()
	void DisableAllNails()
	{
		for(auto Group : Groups)
		{
			for(auto Nail : Group.Nails)
			{
				Nail.DeactivateNail();
			}

			Group.OnGroupDisabled();
		}
	}
}

AToolBoxRainControllerNew FindRootController(AActor Child)
{
	AActor Parent = Child;
	while(Parent != nullptr)
	{
		auto Controller = Cast<AToolBoxRainControllerNew>(Parent);
		if (Controller != nullptr)
			return Controller;

		Parent = Parent.GetAttachParentActor();
	}

	return nullptr;
}
