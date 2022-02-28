enum ETreeBoatForceVolumeType
{
	Directional,
	Radial,
	MTD
}

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ATreeBoatForceVolume : AVolume
{
	UPROPERTY()
	ETreeBoatForceVolumeType ForceVolumeType;

	UPROPERTY()
	float Force = 1000.f;

	UPROPERTY()
	bool bUseForceAlpha;

	UPROPERTY()
	int Group = 0;

	bool bIsActivated = true;

	FVector ForceOrigin;

	FLinearColor ArrowColor = FLinearColor::LucBlue;
	FLinearColor VolumeColor = FLinearColor::Green;

	default Shape::SetVolumeBrushColor(this, VolumeColor);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		switch (Group)
		{
			case 0:
			{
				ArrowColor = FLinearColor::LucBlue * 0.5f;
				break;
			}
			case 1:
			{
				ArrowColor = FLinearColor::Green * 0.5f;
				break;
			}
			case 2:
			{
				ArrowColor = FLinearColor::Yellow * 0.5f;
				break;
			}
			case 3:
			{
				ArrowColor = FLinearColor::Red * 0.5f;
				break;
			}
		}

		VolumeColor = ArrowColor;

		Shape::SetVolumeBrushColor(this, VolumeColor);

		switch (ForceVolumeType)
		{
			case ETreeBoatForceVolumeType::Directional:
			{
				UArrowComponent Arrow = UArrowComponent::Create(this);			
				Arrow.SetArrowColor(ArrowColor);
				Arrow.SetbAbsoluteScale(true);
				Arrow.SetRelativeLocation(FVector(-100.f, 0.f, 0.f));
				Arrow.SetWorldScale3D(FVector(ActorScale3D.X, ActorScale3D.Y * 4.f, 1.f));
				Arrow.ArrowSize = 2.5f;
				break;
			}
			case ETreeBoatForceVolumeType::Radial:
			{
				int Arrows = 24;
				float ArrowAngle = 360.f / Arrows;

				for (int i = 0; i < Arrows; i++)
				{				
					UArrowComponent Arrow = UArrowComponent::Create(this);
					Arrow.SetRelativeRotation(FRotator(0.f, i * ArrowAngle, 0.f));
					Arrow.SetArrowColor(ArrowColor);
					Arrow.SetbAbsoluteScale(true);
					Arrow.SetWorldScale3D(FVector(ActorScale3D.X, 32.f, 1.f));
					Arrow.ArrowSize = 2.5f;
				}

				break;
			}
			case ETreeBoatForceVolumeType::MTD:
			{
				break;
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch (Group)
		{
			case 0:
			{
				ArrowColor = FLinearColor::LucBlue * 0.5f;
				break;
			}
			case 1:
			{
				ArrowColor = FLinearColor::Green * 0.5f;
				break;
			}
			case 2:
			{
				ArrowColor = FLinearColor::Yellow * 0.5f;
				break;
			}
			case 3:
			{
				ArrowColor = FLinearColor::Red * 0.5f;
				break;
			}
		}

		VolumeColor = ArrowColor;

		switch (ForceVolumeType)
		{
			case ETreeBoatForceVolumeType::Directional:
			{
				ForceOrigin = ActorLocation + ActorForwardVector * -100 * ActorScale3D.X;
				break;
			}
			case ETreeBoatForceVolumeType::Radial:
			{
				ForceOrigin = ActorLocation;
				break;
			}
		}
	}

	UFUNCTION()
	FVector GetVolumeForce(USphereComponent SphereComponent)
	{
		FVector ForceVector;

		if (!bIsActivated)
			return ForceVector;

		switch (ForceVolumeType)
		{
			case ETreeBoatForceVolumeType::Directional:
			{
				ForceVector = ActorForwardVector * Force;
				break;
			}
			case ETreeBoatForceVolumeType::Radial:
			{
				ForceVector = (SphereComponent.WorldLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal() * Force;
				break;
			}
			case ETreeBoatForceVolumeType::MTD:
			{
				FCollisionShape CollisionShape;			
				CollisionShape.SetSphere(SphereComponent.SphereRadius);
				FMTDResult MTD;				
				Trace::ComputeMTD(BrushComponent, MTD, CollisionShape, SphereComponent.GetWorldLocation(), SphereComponent.GetComponentQuat());
				FVector MTDForce = MTD.Direction * (MTD.Distance * Force);
				MTDForce.ConstrainToPlane(FVector::UpVector);
				ForceVector = MTDForce;
				break;
			}
		}

		if (bUseForceAlpha)
		{
			float Alpha = FMath::Clamp(1.f - ((SphereComponent.WorldLocation - ForceOrigin).Size() - SphereComponent.SphereRadius) / ((ActorScale3D.X * 200.f)), 0.f, 1.f);
			ForceVector *= Alpha;
		
		//	PrintToScreen("Alpha" + Alpha);			
		}

		return ForceVector;
	}

	UFUNCTION()
	void ActivateForceVolume()
	{
		bIsActivated = true;
	}

	UFUNCTION()
	void DeactivateForceVolume()
	{
		bIsActivated = false;
	}

}