import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;

class UFishTrackTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FishBehaviour");
	default TickGroup = ECapabilityTickGroups::GamePlay;

    UFishBehaviourComponent BehaviourComponent = nullptr;
	UFishEffectsComponent EffectsComp = nullptr;
	UFishComposableSettings Settings = nullptr;
	FHazeAcceleratedRotator LocalRotation;
	FQuat DefaultRelativeForwardRotation;
	FHazeAcceleratedFloat VisionWidthFactor;
	float DefaultVisionWidth;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = UFishBehaviourComponent::Get(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
        ensure(Settings != nullptr);
		
		if (EffectsComp.Lantern != nullptr)
		{
			// Forward rotation is direction from lantern to center of vision cone
			FTransform Transform = GetLanternParentTransform();
			DefaultRelativeForwardRotation = FQuat(Transform.InverseTransformPosition(BehaviourComponent.VisionCone.WorldLocation).Rotation());
			FQuat(EffectsComp.Lantern.RelativeRotation);
			LocalRotation.SnapTo(FRotator::ZeroRotator);
		}
		
		DefaultVisionWidth = BehaviourComponent.VisionCone.RelativeScale3D.Y;
		VisionWidthFactor.SnapTo(1.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
       	return EHazeNetworkActivation::ActivateLocal;
	}

	FTransform GetLanternParentTransform()
	{
		USceneComponent ParentComp = EffectsComp.Lantern.AttachParent;
		USkinnedMeshComponent ParentMesh = Cast<USkinnedMeshComponent>(ParentComp);
		FTransform Transform = ParentComp.WorldTransform;
		if (ParentMesh != nullptr)
			Transform = ParentMesh.GetSocketTransform(EffectsComp.Lantern.AttachSocketName);		
		Transform.Scale3D = FVector::OneVector;
		return Transform;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (EffectsComp.Lantern != nullptr)
		{
			// Lantern parent transform offset by default rotation 
			FTransform Transform = GetLanternParentTransform();
			if (BehaviourComponent.HasValidTarget())
			{
				// Turn lantern to shine at target
				FVector ToTarget = Transform.InverseTransformPosition(BehaviourComponent.Target.ActorLocation);			
				if (ToTarget.X < 0.f)
					ToTarget.X = 0.f; // Don't track behind lantern 
				// Note: This is now actually clamped in lantern space, not in lantern space with default offset. Fix if necessary!
				LocalRotation.AccelerateTo(ToTarget.Rotation(), 3.f, DeltaTime);	

				// Tighten vision cone
				VisionWidthFactor.AccelerateTo(Settings.VisionConeChaseFraction, 2.f, DeltaTime);
			}
			else
			{
				// Swing back to default rotation and broaden cone
				LocalRotation.AccelerateTo(FRotator::ZeroRotator, 5.f, DeltaTime);	
				VisionWidthFactor.AccelerateTo(1.f, 5.f, DeltaTime);
			}
		}

		// Adjust vision cone direction in local space, offset by inverse default rotation so vision cone will be centered on target
		// Skip tracking only adjust width (by design)
		//EffectsComp.Lantern.SetRelativeRotation(FQuat(LocalRotation.Value) * DefaultRelativeForwardRotation.Inverse());

		// Adjust cone width
		FVector Scale = BehaviourComponent.VisionCone.RelativeScale3D;
		Scale.X = DefaultVisionWidth * VisionWidthFactor.Value;
		Scale.Y = DefaultVisionWidth * VisionWidthFactor.Value;
		BehaviourComponent.VisionCone.SetRelativeScale3D(Scale);
    }
}