import Cake.LevelSpecific.SnowGlobe.SnowyOwl.SnowyOwlVisibilityComponent;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSnowOwl;
import Peanuts.Audio.AudioStatics;

class USnowyOwlVisualizerComponent : UActorComponent { }
class USnowyOwlVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowyOwlVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ASnowyOwl SnowyOwl = Cast<ASnowyOwl>(Component.GetOwner());
		USnowyOwlMovementComponent Movement = USnowyOwlMovementComponent::Get(SnowyOwl);
		USnowyOwlVisibilityComponent Visibility = USnowyOwlVisibilityComponent::Get(SnowyOwl);

		if (SnowyOwl == nullptr)
			return;

		DrawCircle(SnowyOwl.ActorLocation, Visibility.NearDistance, FLinearColor::DPink, 5.f, Segments = 32);

		if (Movement.EntrySpline != nullptr)
		{
			FVector EntryLocation = Movement.EntrySpline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);

			DrawDashedLine(SnowyOwl.ActorLocation, EntryLocation, FLinearColor::Green);
			DrawPoint(EntryLocation, FLinearColor::Green, 20.f);
		}

		for (int i = 0; i < Movement.StoredTransitions.Num(); ++i)
		{
			FSnowyOwlTransition& Transition = Movement.StoredTransitions[i];

			int SamplePoints = 50;
			float TangentDistance = Transition.Length * Movement.TangentDistanceScale;
			FVector PreviousLocation = Transition.GetExitLocation();
			for (int j = 1; j < SamplePoints + 1; ++j)
			{
				float Distance = Transition.Length * (j / float(SamplePoints));
				FVector SampleLocation = Transition.GetLocationAtDistance(Distance, TangentDistance);
				DrawLine(PreviousLocation, SampleLocation, FLinearColor::Red, 12.f);
				PreviousLocation = SampleLocation;
			}
		}

		if (Movement.LoopSpline != nullptr)
		{
			float ClosestDistance = Movement.LoopSpline.GetDistanceAlongSplineAtWorldLocation(SnowyOwl.ActorLocation);
			FVector ClosestLocation = Movement.LoopSpline.GetLocationAtDistanceAlongSpline(ClosestDistance, ESplineCoordinateSpace::World);

			DrawDashedLine(SnowyOwl.ActorLocation, ClosestLocation, FLinearColor::Yellow);
			DrawPoint(ClosestLocation, FLinearColor::Yellow, 20.f);
		}
	}
}

class ASnowyOwl : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bComponentUseFixedSkelBounds = true;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightToeBase")
	USwingPointComponent SwingPointComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.bTickWhileDisabled = true;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VerySlow;
	default CrumbComp.UpdateSettings.OptimalCount = 2;

	UPROPERTY(DefaultComponent)
	USnowyOwlMovementComponent MovementComp;

	UPROPERTY(DefaultComponent)
	USnowyOwlVisibilityComponent VisibilityComp;

	UPROPERTY(DefaultComponent)
	USnowyOwlVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(Category = "Snowy Owl")
	ULocomotionFeatureSnowOwl Feature;

	UPROPERTY(Category = "Snowy Owl")
	float PlayerPullStrength = 250.f;

	UPROPERTY(Category = "Snowy Owl")
	bool bStartDisabled = false;

	UPROPERTY(Category = "Snowy Owl")
	float CullDistanceMultiplier = 1.0f;

	UPROPERTY(Category = "Snowy Owl|Audio Events")
	UAkAudioEvent AttachAudioEvent;

	UPROPERTY(Category = "Snowy Owl|Audio Events")
	UAkAudioEvent ScreechAudioEvent;

	TArray<AHazePlayerCharacter> AttachedPlayers;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetCullDistance(Editor::GetDefaultCullingDistance(Mesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComponent.OnSwingPointAttached.AddUFunction(this, n"HandlePlayerAttached");
		SwingPointComponent.OnSwingPointDetached.AddUFunction(this, n"HandlePlayerDetached");

		PlayIdleOverrideAnimations(Feature.Fly);

		if (bStartDisabled)
			DisableActor(this);

		MovementComp.Transform = ActorTransform;
		CrumbComp.IncludeCustomParamsInActorReplication(ActorTransform.Location, ActorTransform.Rotator(), this);
	}

	UFUNCTION()
	void EnableSnowyOwl()
	{
		EnableActor(this);
		HazeAkComp.HazePostEvent(ScreechAudioEvent);
	}

	UFUNCTION()
	bool HasAttachedPlayers()
	{
		return AttachedPlayers.Num() > 0;
	}

	UFUNCTION()
	private void HandlePlayerAttached(AHazePlayerCharacter Player)
	{
		if (AttachedPlayers.Num() <= 0)
		{
			FHazeAnimationDelegate AnimationDelegate;
			PlayOverrideAnimation(AnimationDelegate, Feature.Override);
		}

		AttachedPlayers.AddUnique(Player);
		HazeAkComp.HazePostEvent(AttachAudioEvent);
	}

	UFUNCTION()
	private void HandlePlayerDetached(AHazePlayerCharacter Player)
	{
		if (AttachedPlayers.Contains(Player))
			AttachedPlayers.Remove(Player);

		if (AttachedPlayers.Num() <= 0)
			StopOverrideAnimation(Feature.Override.Animation);
	}
}