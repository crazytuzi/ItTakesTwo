import Cake.LevelSpecific.SnowGlobe.SnowyOwl.SnowyOwlNames;
import Cake.LevelSpecific.SnowGlobe.SnowyOwl.SnowyOwlMovementComponent;
import Cake.LevelSpecific.SnowGlobe.SnowyOwl.AnimNotify_SnowyOwlNeutralPose;

class USnowyOwlVisibilityComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
	UPROPERTY(NotVisible)
	UHazeSkeletalMeshComponentBase Mesh;
	UPROPERTY(NotVisible)
	USnowyOwlMovementComponent MovementComp;

	// Distance at which the owl will be fully animated.
	UPROPERTY(EditDefaultsOnly)
	float NearDistance = 4000.f;

	ESnowyOwlVisibility Visibility;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		MovementComp = USnowyOwlMovementComponent::Get(Owner);

		// Ensures we only go static during neutral poses, otherwise we might get stuck in the middle of an animation; looks real bad
		// Also ensures we don't T-Pose in the beginning, as we have time to play some of the initial animation
		// Not as performant as just turning updates off, but hopefully a decent middle ground between not looking like garbage and opting
		Mesh.BindAnimNotifyDelegate(UAnimNotify_SnowyOwlNeutralPose::StaticClass(), FHazeAnimNotifyDelegate(this, n"HandleNeutralAnimNotify"));
	}

	void UpdateVisibility(bool bForceAnimated = false)
	{
		TPerPlayer<float> Distance;
		for (auto Player : Game::Players)
		{
			Distance[Player.Player] = (Player.ActorLocation - MovementComp.Transform.Location).SizeSquared();
		}

		bool bVisible = Mesh.WasRecentlyRendered();
		float ClosestDistanceSqr = FMath::Min(Distance[0], Distance[1]);
		float NearDistanceSqr = FMath::Square(NearDistance);

		Visibility = ESnowyOwlVisibility::Static;
		if ((ClosestDistanceSqr <= NearDistanceSqr && bVisible) || bForceAnimated)
		{
			Visibility = ESnowyOwlVisibility::Animated;

			// No prerequisites for static => animated
			Mesh.bNoSkeletonUpdate = false;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsAnimated()
	{
		return Visibility == ESnowyOwlVisibility::Animated;
	}

	UFUNCTION()
	private void HandleNeutralAnimNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, const UAnimNotify AnimNotify)
	{
		if (Visibility != ESnowyOwlVisibility::Static)
			return;
		
		Mesh.bNoSkeletonUpdate = true;
	}
}