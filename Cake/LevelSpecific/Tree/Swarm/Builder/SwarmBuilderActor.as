
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Builder.SwarmBuilderStructs;
import Cake.LevelSpecific.Tree.Queen.QueenSettings;
import Cake.LevelSpecific.Tree.Queen.QueenBehaviourComponent;
import Peanuts.Spline.HelixSplineActor;

UCLASS(HideCategories = "Activation Replication Input Cooking LOD Actor")
class ASwarmBuilderActor : AHazeActor
{
	// Helps you find the actor in the level. 
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UInstancedStaticMeshComponent InstancedEntityMesh;
	default InstancedEntityMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default InstancedEntityMesh.SetCollisionProfileName(n"NoCollision");
	default InstancedEntityMesh.bGenerateOverlapEvents = false;
	default InstancedEntityMesh.BodyInstance.bNotifyRigidBodyCollision = false;
	default InstancedEntityMesh.SetGenerateOverlapEvents(false);

	// Actor which will recruit the newly built swarms. (An actor which has a SwarmBossComp)
	UPROPERTY()
	AHazeActor QueenActor;

	// Swarm that will accumulate incoming particles
	UPROPERTY()
	TSubclassOf<ASwarmActor> SwarmClass;

	// All splines that make up the builder assembly line.
    UPROPERTY()
    TArray<AActor> SplineActors;

	UPROPERTY()
	USwarmAnimationSettingsDataAsset AnimationPlayedWhileBeingBuilt;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transient

	int32 SpawnedSwarmCounter = 0;

	UQueenSettings Settings;
    float FinishedFraction = 0.f;
    TArray<FBuilderSpline> BuilderSplines;
	ASwarmActor SwarmBeingBuilt = nullptr;

	// will look for all Helix spline actors in level and assign them
	UFUNCTION(CallInEditor)
	void AutoAssignSplineActors()
	{
		TArray<AHelixSplineActor> AllSplines;
		GetAllActorsOfClass(AHelixSplineActor::StaticClass(), SplineActors);
	}

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Match, Sap and swarm all have May as controlside. 
		SetControlSide(Game::GetMay());

		SwarmBeingBuilt = GetSwarmToBuild();
		Settings = UQueenSettings::GetSettings(QueenActor);
		CreateAndAssignBuilders();

		Bubble.SetVisibility(false);
	}

 	UFUNCTION(BlueprintOverride)
	void Tick(const float DeltaTime)
	{
 		UpdateBuilders(DeltaTime);
		UpdateInstancedMesh();

		// this is fine, no need for any ::max()
        FinishedFraction = CalcFinishedFraction();

		// PrintToScreenScaled("BuildTime: " + GetTimeToBuildSwarm(), 0.f, FLinearColor::Yellow, 2.f);
		// if(DebugTimestampBuidTime == -1.f && FinishedFraction == 0.f && GetTimeToBuildSwarm() > 0.f)
		// {
		// 	DebugTimestampBuidTime = Time::GetGameTimeSeconds();
		// 	Print("Start building");
		// }
		// else if(DebugTimestampBuidTime != -1.f && FinishedFraction == 1.f)
		// {
		// 	float TimeToBuildTheSwarm = Time::GetGameTimeSince(DebugTimestampBuidTime);
		// 	Print("Time to build swarm " + TimeToBuildTheSwarm, 5.f, FLinearColor::Yellow);
		// 	DebugTimestampBuidTime = -1.f;
		// }
		// else if(GetTimeToBuildSwarm() <= 0.f && DebugTimestampBuidTime != -1.f)
		// {
		// 	DebugTimestampBuidTime = -1.f;
		// 	Print("Reset", Duration = 1.f);
		// }

		// UpdateSphereScale(DeltaTime);

        if(FinishedFraction >= 1.f 
		&& MaxSwarmCountReached() == false 
		&& ShouldStopBuildingSwarms() == false
		&& HasControl())
		{
			NetHandleFinishedSwarm();
		}

#if TEST 
		if(!Game::May.bIsParticipatingInCutscene && !Game::Cody.bIsParticipatingInCutscene)
		{
			for(ASwarmActor IterSwarm : GetQueenComponent().Swarms)
			{
				devEnsure(!IterSwarm.IsActorDisabled(), IterSwarm.GetName() + ", which is disabled," " has been added to the Queens (active) Swarm Array. This will permanently slow down the swarm builder, unless the disabled swarm is killed by script. \n Please notify Sydney about this");
			}
		}
#endif TEST

//       DebugDraw();

	}

	UFUNCTION(NetFunction)
	void NetHandleFinishedSwarm()
	{
		SphereScale = 0.f;
		SphereScale_Speed = 0.f;

		for(FBuilderSpline& BuilderSpline : BuilderSplines)
			BuilderSpline.Reset();

		SwarmBeingBuilt.HandleSwarmBuilderRevival();

		// Deliver the new swarm to the boss once done. 
		GetQueenComponent().RecruitSwarm(SwarmBeingBuilt);

		// Start building a new one. 
		StartBuildingNewSwarm();
	}

	float DebugTimestampBuidTime = -1.f;

	void StartBuildingNewSwarm()
	{
		SwarmBeingBuilt = GetSwarmToBuild();

		for (int i = 0; i < BuilderSplines.Num(); i++)
			BuilderSplines[i].Mesh = SwarmBeingBuilt.SkelMeshComp;
	}

	ASwarmActor GetSwarmToBuild() 
	{
		ASwarmActor Swarm = Cast<ASwarmActor>(SpawnActor(SwarmClass.Get(), bDeferredSpawn = true, Level = this.Level));
		Swarm.MakeNetworked(this, SpawnedSwarmCounter++);

		Swarm.MovementComp.ArenaMiddleActor = QueenActor;

		// make the swarm invulnerable before we finish spawning just in case. 
		TArray<USwarmSkeletalMeshComponent> SwarmSkelMeshes;
		Swarm.GetComponentsByClass(SwarmSkelMeshes);
		for (USwarmSkeletalMeshComponent SwarmMeshIter : SwarmSkelMeshes)
			SwarmMeshIter.bInvulnerable = true;
		Swarm.bInvulnerable = true;

		FinishSpawningActor(Swarm);

		// Teleport swarm to builder
		Swarm.TeleportSwarm(GetActorTransform());

		if(AnimationPlayedWhileBeingBuilt != nullptr)
			Swarm.PlaySwarmAnimation(AnimationPlayedWhileBeingBuilt, this, 0.f);

		// Attach it to the builder in case it moves during the building process
		Swarm.AttachToActor(this, NAME_None, EAttachmentRule::SnapToTarget);
		
		// hide all particles
		Swarm.KillSwarm();

		// init swarm revival
		Swarm.SetInvulnerabilityFlag(true);
		Swarm.PrepareSwarmForRevival();

		return Swarm;
	}

	float GetTimeToBuildSwarm() const
	{
		const auto QueenComp = GetQueenComponent();
		const int NumSwarmsActive = QueenComp != nullptr ? QueenComp.Swarms.Num() : 0;
		const float BuildTime = Settings.Builder.GetBuildTime(NumSwarmsActive); 
		return BuildTime;
	}

	void UpdateBuilders(const float Dt)
	{
		// how long it should take to build 1 swarm
		const float BuildTime = GetTimeToBuildSwarm();

		// network data to be sent over
		TArray<FBuilderSplineNetworkData> BuilderSplineNetworkDataContainer;
		BuilderSplineNetworkDataContainer.Reserve(BuilderSplines.Num());

		// update activity on all splines
		for(int i = 0; i < BuilderSplines.Num(); ++i)
        {
			BuilderSplines[i].UpdateTimeBetweenReleasesAndEntitySpeed(BuildTime);

			// update active ones and account for which ones should be retired
			BuilderSplines[i].UpdateActiveEntities(Dt);

			if (!MaxSwarmCountReached() && BuilderSplines[i].ShouldProcessEntityQueue())
			{
				// network data associated with this spline
				FBuilderSplineNetworkData BuilderSplineNetworkData;

				// figure out how many queued entities should be released on the spline
				BuilderSplines[i].ProcessEntityQueue(BuilderSplineNetworkData.NumEntitiesToRelease, Dt);

				// Only send over data if we need to
				if (BuilderSplineNetworkData.NumEntitiesToRelease != 0)
				{
					BuilderSplineNetworkData.BuilderSplineIdentifierIndex = i;
					BuilderSplineNetworkDataContainer.Add(BuilderSplineNetworkData);
				}
			}

		}

		// Release new entities on the spline 
		if(HasControl() && BuilderSplineNetworkDataContainer.Num() > 0)
		{
			NetReleaseQueuedEntities(BuilderSplineNetworkDataContainer);
		}

	}

	UFUNCTION(NetFunction)
	void NetReleaseQueuedEntities(TArray<FBuilderSplineNetworkData> InBuilderSplineNetworkDataContainer)
	{
		for (FBuilderSplineNetworkData& IterBuilderSplineNetworkData : InBuilderSplineNetworkDataContainer)
		{
			FBuilderSpline& BuilderSpline = BuilderSplines[IterBuilderSplineNetworkData.BuilderSplineIdentifierIndex];

//			Print("Spline "+
//				IterBuilderSplineNetworkData.BuilderSplineIdentifierIndex + " | " +
//				IterBuilderSplineNetworkData.NumEntitiesToRelease);

			while (IterBuilderSplineNetworkData.NumEntitiesToRelease > 0)
			{
				BuilderSpline.ReleaseQueuedEntity(0);
				--IterBuilderSplineNetworkData.NumEntitiesToRelease;
			}
		}
	}

	bool MaxSwarmCountReached() const
	{
		return GetQueenComponent().Swarms.Num() >= 4;
	}

	bool ShouldStopBuildingSwarms() const
	{
		const int NumSwarmsActive = GetQueenComponent().Swarms.Num();
 		return Settings.Builder.GetBuildTime(NumSwarmsActive) == -1.f; 
	}

	float GetTimeBetweenReleases() const
	{
		int NumSwarmsActive = 0;

		// the comp will be nullptr when inspecting with the angelscript debugger...
		const UQueenBehaviourComponent QueenComp = GetQueenComponent();
		if (QueenComp != nullptr)
		{
			NumSwarmsActive = QueenComp.Swarms.Num();
		}

 		const float BuildTime = Settings.Builder.GetBuildTime(NumSwarmsActive); 
		const float FinalTime = BuildTime == -1.f ? BIG_NUMBER : BuildTime;

		return FinalTime; 
	} 

	void UpdateInstancedMesh() 
	{
		if (InstancedEntityMesh.StaticMesh == nullptr)
			return;

		// Figure out how many active entities we have 
		int NumActiveEntities = 0;
		for (FBuilderSpline& BuilderSpline : BuilderSplines)
		{
			for (int i = BuilderSpline.ActiveEntities.Num() - 1; i >= 0; i--)
			{
				++NumActiveEntities;
			}
		}

		// Only Update transform for meshes that are being used
		int Idx = 0;
		for (FBuilderSpline& BuilderSpline : BuilderSplines)
		{
			for (int i = BuilderSpline.ActiveEntities.Num() - 1; i >= 0 ; i--)
			{
				const FBuilderEntity& Entity = BuilderSpline.ActiveEntities[i];

				InstancedEntityMesh.UpdateInstanceTransform(
					Idx,
					FTransform(Entity.Rotation, Entity.Location),
					bWorldSpace = true,
					bMarkRenderStateDirty = Idx == NumActiveEntities - 1 ? true : false,
					bTeleport = true
				);
				++Idx;
			}
		}

 		// Zero the scale for instanced meshes that aren't being used
		TArray<int> InactiveIndicies;
		for(int i = Idx; i < InstancedEntityMesh.GetInstanceCount(); ++i)
		{
			FTransform InstanceTransform; 
			InstancedEntityMesh.GetInstanceTransform(
				i,
				InstanceTransform,
				bWorldSpace = false
			);

			if(InstanceTransform.GetScale3D().IsZero() == false)
				InactiveIndicies.Add(i);
		} 

		// Handle the instanced meshes that need to go  
		for(int i = 0; i < InactiveIndicies.Num(); ++i)
		{
			InstancedEntityMesh.UpdateInstanceTransform(
				InactiveIndicies[i],
				FTransform(FQuat::Identity, FVector::ZeroVector, FVector::ZeroVector),
				bWorldSpace = false,
				bMarkRenderStateDirty = i == InactiveIndicies.Num() - 1 ? true : false,
				//bMarkRenderStateDirty = false,
				bTeleport = true
			);
		}

	}

	UQueenBehaviourComponent GetQueenComponent() const
	{
		if (QueenActor != nullptr)
			return UQueenBehaviourComponent::Get(QueenActor);
		return nullptr;
	}

	bool IsInsideOrOnSwarmBounds(FVector InLocation) const
	{
		FVector Origin, BoxExtent;
		SwarmBeingBuilt.GetActorBounds(false, Origin, BoxExtent);
		const FBox BoundingBox = FBox(Origin - BoxExtent, Origin + BoxExtent);
		return BoundingBox.IsInsideOrOn(InLocation);
	}

	void CreateAndAssignBuilders()
	{
		// Create SplineBuilders (the managers of the entities)
        BuilderSplines.Reset();
        for(AActor SplineActor : SplineActors)
        {
            USplineComponent Spline = USplineComponent::Get(SplineActor);
            if(Spline != nullptr)
            {
                FBuilderSpline BuilderSpline;
                BuilderSpline.Spline = Spline;
				BuilderSpline.Mesh = SwarmBeingBuilt.SkelMeshComp;
                BuilderSplines.Add(BuilderSpline);
            }
        }

        ensure(BuilderSplines.Num() > 0);

		// Create Entity builders and assign them task.
        int SplineIdx = -1;
        const TArray<FName> BoneNames = SwarmBeingBuilt.SkelMeshComp.GetAllSwarmSocketNames();
		for (int i = 0; i < BoneNames.Num(); ++i)
		{
			FBuilderEntity BuilderEntity;

            SplineIdx = FMath::Fmod(SplineIdx + 1, BuilderSplines.Num());

			const FVector EntityStartPos = BuilderSplines[SplineIdx].Spline.GetLocationAtDistanceAlongSpline(
				0.f,
				ESplineCoordinateSpace::World
			);
			BuilderEntity.Location = EntityStartPos;
			BuilderEntity.DesiredLocation = EntityStartPos;

            //Assign bone to particle
			BuilderEntity.AssignedBoneName = BoneNames[i];

			// Setup the instanced static mesh
			FTransform StartTransform;
			StartTransform.SetLocation(EntityStartPos);
			StartTransform.SetScale3D(FVector::ZeroVector);
			InstancedEntityMesh.AddInstanceWorldSpace(StartTransform);

			BuilderEntity.ResetInitialTransientValues();

            // Assign Entity to spline.
            BuilderSplines[SplineIdx].AssignedEntities.Add(BuilderEntity);
            BuilderSplines[SplineIdx].QueuedEntities.Add(BuilderEntity);
		}

		for(FBuilderSpline& BuilderSplineIter : BuilderSplines)
		{
			if (BuilderSplineIter.AssignedEntities.Num() > 0)
			{
				BuilderSplineIter.AssignedEntitiesFactor = 1.f / BuilderSplineIter.AssignedEntities.Num();
				// BuilderSplineIter.TimeSinceRelease = BIG_NUMBER * BuilderSplineIter.AssignedEntitiesFactor;
			}
		}

	}

    float CalcFinishedFraction() const 
    {
        float TotalFinished = 0;
        float TotalAssigned = 0;

		if(BuilderSplines.Num() <= 0)
			return 0.f;

		for (int i = 0; i < BuilderSplines.Num(); i++)
		{
            TotalFinished += BuilderSplines[i].FinishedEntities.Num();
            TotalAssigned += BuilderSplines[i].AssignedEntities.Num();
		}

        // This is dangerous. The value might never go over 1.
        //return ((TotalFinished / TotalAssigned) % 1.f);
        //return (TotalFinished / TotalAssigned);
        return FMath::Clamp(TotalFinished / TotalAssigned, 0.f, 1.f);
    }

	// Will move all spline (End) points to the swarm builder sphere.
	UFUNCTION(CallInEditor)
	void SnapSplineEndsToRoot()
	{
		for(AActor SplineActor : SplineActors)
		{
			if(SplineActor == nullptr)
				continue;

			USplineComponent Spline = USplineComponent::Get(SplineActor); 
			Spline.SetLocationAtSplinePoint(
				Spline.GetNumberOfSplinePoints() - 1,
				GetActorLocation(), 
				ESplineCoordinateSpace::World, 
				true
			);
		}
	}

	// Will move all spline (Start) points to the swarm builder sphere.
	// UFUNCTION(CallInEditor)
	void SnapSplineStartsToRoot()
	{
		for(AActor SplineActor : SplineActors)
		{
			USplineComponent Spline = USplineComponent::Get(SplineActor); 
			Spline.SetLocationAtSplinePoint(
				0,
				GetActorLocation(), 
				ESplineCoordinateSpace::World, 
				true
			);
		}
	}

    void DebugDraw()
    {
		PrintToScreen("NumActiveSwarms: "+ GetQueenComponent().Swarms.Num() + "\n",  Color = FLinearColor::Green);
		// PrintToScreen("Finished Fraction: "+ FinishedFraction, Color = FLinearColor::Green);
		// System::DrawDebugSphere(SwarmBeingBuilt.SkelMeshComp.CenterOfParticles, 10.f);
        // System::DrawDebugSphere(SwarmBeingBuilt.GetActorLocation(), 10.f);

		for(ASwarmActor IterSwarm : GetQueenComponent().Swarms)
		{
			FVector WorldExtent = IterSwarm.SkelMeshComp.GetWorldBoundExtent();
			// PrintToScreen("Swarm: " + IterSwarm.GetName());

			bool DisabledYes = IterSwarm.IsActorDisabled();
			ensure(!DisabledYes);

			// System::DrawDebugBox(
			// 	IterSwarm.Collider.GetWorldLocation(),
			// 	WorldExtent,
			// 	FLinearColor::Red,
			// 	FRotator::ZeroRotator,
			// 	0.f,
			// 	10.f
			// );

		}

		System::DrawDebugBox(
			SwarmBeingBuilt.Collider.GetWorldLocation(),
			SwarmBeingBuilt.SkelMeshComp.GetWorldBoundExtent(),
			FLinearColor::Yellow,
			FRotator::ZeroRotator,
			0.f,
			10.f
		);

		int NumQueued = 0, NumActive = 0, NumFinished = 0, NumAssigned = 0;
        for(FBuilderSpline& BuilderSpline : BuilderSplines)
        {
			NumQueued += BuilderSpline.QueuedEntities.Num();
			NumActive += BuilderSpline.ActiveEntities.Num();
			NumFinished += BuilderSpline.FinishedEntities.Num();
			NumAssigned += BuilderSpline.AssignedEntities.Num();

			// PrintToScreen("Queued: " + BuilderSpline.QueuedEntities.Num());
			// PrintToScreen("Active: " + BuilderSpline.ActiveEntities.Num());
			// PrintToScreen("Finished: " + BuilderSpline.FinishedEntities.Num());
			// PrintToScreen("TimeSinceRelease: " + BuilderSpline.TimeSinceRelease);
			// PrintToScreen("Assigned: " + BuilderSpline.AssignedEntities.Num());
            // PrintToScreen("Spline: " + BuilderSpline.Spline.GetOwner());

			float PointBaseSize = 5.f;

            for(FBuilderEntity& BuilderEntity : BuilderSpline.ActiveEntities)
            {
                // Draw destinations
                FVector EndLoc = SwarmBeingBuilt.SkelMeshComp.GetSocketLocation(BuilderEntity.AssignedBoneName);
                System::DrawDebugPoint(EndLoc, PointBaseSize, FLinearColor::LucBlue);

                // // Draw desired locations
                // FVector DesiredLoc = BuilderEntity.DesiredLocation;
                // System::DrawDebugPoint(DesiredLoc, PointBaseSize, FLinearColor::Green);

                // // Draw current loations 
                // FVector CurrentLoc = BuilderEntity.Location;
                // System::DrawDebugPoint(CurrentLoc, PointBaseSize * 2.f, FLinearColor::Yellow);
            }

            for(FBuilderEntity& BuilderEntity : BuilderSpline.FinishedEntities)
            {
//                // Finsihed entities 
//                FVector FinLoc = SwarmBeingBuilt.SkelMeshComp.GetSocketLocation(BuilderEntity.AssignedBoneName);
//                System::DrawDebugPoint(FinLoc, PointBaseSize * 0.5f, FLinearColor::Red);
            }

			// PrintToScreen("//////////////////////////////////////////////", Color = FLinearColor::Yellow);
        }

		// PrintToScreen("TimebetweenReleases: " + GetTimeBetweenReleases());
		PrintToScreen("Queued: " + NumQueued);
		PrintToScreen("Active: " + NumActive);
		PrintToScreen("Finished: " + NumFinished);
		// PrintToScreen("Assigned: " + NumAssigned);
		// PrintToScreen("//// SwarmBuilder", Color = FLinearColor::Yellow);
		PrintToScreen("//////////////////////////////////////////////", Color = FLinearColor::Yellow);

    }

	//////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Bubble;
	default Bubble.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Bubble.SetCollisionProfileName(n"NoCollision");
	default Bubble.bGenerateOverlapEvents = false;
	default Bubble.BodyInstance.bNotifyRigidBodyCollision = false;
	default Bubble.SetGenerateOverlapEvents(false);

	// TEMP until we get Niagara working
    float SphereScale = 0.f;
    float SphereScale_Speed = 0.f;
	void UpdateSphereScale(const float Dt)
	{
        float DesiredRadius = FMath::Lerp(
            0.f,
            2.5f,
            FMath::Pow(FinishedFraction, 0.5f)
            //FinishedFraction
        );

        float Stiffness = 50.f;
		float TimeBetween = GetTimeBetweenReleases();
		if(TimeBetween < 100.f)
		{
			Stiffness *= TimeBetween;
			Stiffness = (FMath::RandRange(0.f, Stiffness)*0.8f) + (0.2f * Stiffness);
		}

        const float Damping = 0.3f;
		const float IdealDampingValue = 2.f * FMath::Sqrt(Stiffness);

		const float ToCurrent = SphereScale - DesiredRadius;

		SphereScale_Speed -= (ToCurrent*Dt*Stiffness);
		SphereScale_Speed /= (1.f + (Dt*Dt*Stiffness) + (Damping*IdealDampingValue*Dt));

        SphereScale += (SphereScale_Speed * Dt);

		Bubble.SetWorldScale3D(FVector::OneVector * SphereScale);
	}
	//////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////

}






