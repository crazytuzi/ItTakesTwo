import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Peanuts.Audio.VO.PatrolActorAudioComponent;
import Vino.BouncePad.BouncePadResponseComponent;

class USnowFolkCrowdVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowFolkCrowdVisComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
    	auto CrowdMember = Cast<ASnowFolkCrowdMember>(Component.Owner);

		auto ParentLeader = Cast<ASnowFolkCrowdMember>(CrowdMember.GetAttachParentActor());
		if (ParentLeader != nullptr)
			DrawNetwork(ParentLeader);
		else
			DrawNetwork(CrowdMember);
    }

    void DrawNetwork(ASnowFolkCrowdMember Leader)
    {
    	if (Leader.VisFrame == GFrameNumber)
    		return;

    	Leader.VisFrame = GFrameNumber;
    	FVector Offset = FVector(0.f, 0.f, 150.f);

    	TArray<AActor> Children;
    	Leader.GetAttachedActors(Children);
    	for(auto Child : Children)
    	{
    		auto Follower = Cast<ASnowFolkCrowdMember>(Child);
    		if (Follower == nullptr)
    			continue;

    		FVector Dir = Leader.ActorLocation - Follower.ActorLocation;
    		Dir.Normalize();

    		FVector Src = Follower.ActorLocation + Dir * 180.f + Offset;
    		FVector Dst = Leader.ActorLocation - Dir * 180.f + Offset;
	    	DrawArrow(Src, Dst, FLinearColor::Red, 10.f, 5.f);
	    	DrawWireSphere(Src, 15.f, FLinearColor::Red, 5.f);
	    }
	}
}

class USnowFolkCrowdVisComponent : UActorComponent {}
class ASnowFolkCrowdMember : AHazeActor
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;
	default SkeletalMeshComponent.AnimationMode = EAnimationMode::AnimationSingleNode;
	default SkeletalMeshComponent.bComponentUseFixedSkelBounds = true;
	default SkeletalMeshComponent.SkeletalMesh = Asset("/Game/Characters/SnowFolk/SnowFolk.SnowFolk");

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollision;
	default SphereCollision.RelativeLocation = FVector(0.f, 0.f, 165.f);
	default SphereCollision.SphereRadius = 160;
	default SphereCollision.CollisionProfileName = n"BlockAll";
	default SphereCollision.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadResponseComp;

	UPROPERTY(DefaultComponent)
	USnowFolkCrowdVisComponent VisComp;
	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent AudioComp;

	UPROPERTY(DefaultComponent)
	UPatrolActorAudioComponent PatrolAudioComp;
	default PatrolAudioComp.bAutoRegister = false;

	UPROPERTY(Category = "Bouncing")
	float BounceVelocity = 1000.f;

	UPROPERTY(Category = "Bouncing")
	float BounceHorizontalVelocityModifier = 0.5f;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceAudioEvent;

	UPROPERTY(Category = "Dev")
	AActor ActorToReplace;

	uint32 VisFrame;
	UAkAudioEvent PendingAnimationEvent;

	private bool bPendingDelayedAnimationAudio = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ActorToReplace != nullptr)
		{
			auto SkelMesh = USkeletalMeshComponent::Get(ActorToReplace);
			if (SkelMesh != nullptr)
			{
				SkeletalMeshComponent.SkeletalMesh = SkelMesh.SkeletalMesh;
				for(int i=0; i<SkelMesh.NumMaterials; ++i)
					SkeletalMeshComponent.SetMaterial(i, SkelMesh.GetMaterial(i));

				SkeletalMeshComponent.AnimationMode = SkelMesh.AnimationMode;
				SkeletalMeshComponent.AnimationData = SkelMesh.AnimationData;
				SkeletalMeshComponent.RelativeTransform = GetActorRelativeTransform(SkelMesh);

				ActorTransform = ActorToReplace.ActorTransform;
				ActorToReplace.DestroyActor();
			}

			ActorToReplace = nullptr;
		}

		auto Leader = Cast<ASnowFolkCrowdMember>(GetAttachParentActor());
		if (Leader != nullptr)
		{
			SkeletalMeshComponent.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
			SkeletalMeshComponent.AnimationMode = Leader.SkeletalMeshComponent.AnimationMode;
			SkeletalMeshComponent.AnimationData = Leader.SkeletalMeshComponent.AnimationData;
			SkeletalMeshComponent.SetMasterPoseComponent(Leader.SkeletalMeshComponent);
		}
		else
		{
			SkeletalMeshComponent.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
			SkeletalMeshComponent.SetMasterPoseComponent(nullptr);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComponent.OnActorDownImpactedByPlayer.AddUFunction(this, n"HandlePlayerDownImpact");
		BouncePadResponseComp.OnBounce.AddUFunction(this, n"HandlePlayerBounce");
	}

	UFUNCTION()
	void HandlePlayerDownImpact(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", BounceVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", BounceHorizontalVelocityModifier);
		Player.SetCapabilityAttributeObject(n"BouncedObject", this);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

	UFUNCTION()
	void HandlePlayerBounce(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		if (BounceAudioEvent != nullptr)
			AudioComp.HazePostEvent(BounceAudioEvent);
	}

	bool InAnyPlayersView()
	{
		// If within 500 sqrd of any player, return true
		for(auto& Player : Game::GetPlayers())
		{
			const float DistSqrd = Player.GetActorLocation().DistSquared(GetActorLocation());
			if(DistSqrd < FMath::Square(500))
				return true;

			if(SceneView::IsInView(Player, GetActorLocation()))
				return true;
		}
		
		return false;
	}

	void PerformAnimationAudioFromLeader(UAkAudioEvent& AudioEvent)
	{
		TArray<AActor> Children;
		GetAttachedActors(Children);
		if(Children.Num() == 0)
			return;

		for(auto& Child : Children)
		{
			ASnowFolkCrowdMember CrowdMember = Cast<ASnowFolkCrowdMember>(Child);
			if(CrowdMember == nullptr)
				continue;

			CrowdMember.QueryAnimationAudio(AudioEvent);
		}

		QueryAnimationAudio(AudioEvent);
	}

	void QueryAnimationAudio(UAkAudioEvent& AudioEvent)
	{
		// Post event on every child in view of players, delay the ones out of view to spread
		// the audio of  synced animations in time

		if(InAnyPlayersView())
			UHazeAkComponent::HazePostEventFireForget(AudioEvent, GetActorTransform());
		else
		{
			const float RandDelay = FMath::RandRange(0.1f, 0.5f);
			PendingAnimationEvent = AudioEvent;
			System::SetTimer(this, n"PerformAnimationAudioFromLeader_Delayed", RandDelay, false);
		}
	}

	UFUNCTION()
	void PerformAnimationAudioFromLeader_Delayed()
	{
		if(InAnyPlayersView())
			return;

		UHazeAkComponent::HazePostEventFireForget(PendingAnimationEvent, GetActorTransform());	
	}

	FTransform GetActorRelativeTransform(USceneComponent Child)
	{
		FTransform Result = Child.RelativeTransform;
		USceneComponent Parent = Child.AttachParent;

		while(Parent != nullptr)
		{
			if (Parent.AttachParent == nullptr)
				break;

			Result = Result * Parent.RelativeTransform;
			Parent = Parent.AttachParent;
		}

		return Result;
	}
}