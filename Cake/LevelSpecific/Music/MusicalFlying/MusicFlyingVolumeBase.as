
UCLASS(Abstract, HideCategories = "Cooking Replication Collision Debug Actor Tags HLOD Mobile AssetUserData Input LOD Rendering")
class AMusicFlyingVolumeBase : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"NoCollision");
	default Shape::SetVolumeBrushColor(this, FLinearColor::LucBlue);

	UPROPERTY()
	bool bStartActive = false;

	UPROPERTY()
	bool bApplySheets = false;

	protected TArray<UPrimitiveComponent> _CachedBrushCollection;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		_CachedBrushCollection.Empty();
		for(UPrimitiveComponent Prim : BrushCollection)
			Prim.SetCollisionProfileName(n"NoCollision");
	}

	default BrushComponent.bHiddenInGame = false;

	UFUNCTION()
	void ActivateFlyingVolume()
	{
		for(UPrimitiveComponent Brush : BrushCollection)
		{
			Brush.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
			Brush.OnComponentEndOverlap.AddUFunction(this, n"BrushEndOverlap");
			Brush.SetCollisionProfileName(n"TriggerOnlyPlayer", true);
		}
	}

	UFUNCTION()
	void DeactivateFlyingVolume()
	{
		for(UPrimitiveComponent Brush : BrushCollection)
		{
			Brush.SetCollisionProfileName(n"NoCollision", true);
			Brush.OnComponentBeginOverlap.Clear();
			Brush.OnComponentEndOverlap.Clear();
		}
	}

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, const FHitResult&in Hit) 
	{

	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{

	}

	protected TArray<UPrimitiveComponent>& GetBrushCollection() property
	{
		if(_CachedBrushCollection.Num() == 0)
		{
			GetComponentsByClass(_CachedBrushCollection);
		}

		return _CachedBrushCollection;
	}

	FVector GetVolumeExtent() const property
	{
		return BrushComponent.BoundsExtent;
	}

	FVector GetPlaneForwardLocation() const property
	{
		return BrushComponent.WorldLocation + BrushComponent.ForwardVector * VolumeExtent.X;
	}

	FVector GetPlaneBackLocation() const property
	{
		return BrushComponent.WorldLocation - BrushComponent.ForwardVector * VolumeExtent.X;
	}

	FVector GetPlaneRightLocation() const property
	{
		return BrushComponent.WorldLocation + BrushComponent.RightVector * VolumeExtent.Y;
	}

	FVector GetPlaneLeftLocation() const property
	{
		return BrushComponent.WorldLocation - BrushComponent.RightVector * VolumeExtent.Y;
	}

	FVector GetPlaneUpLocation() const property
	{
		return BrushComponent.WorldLocation + BrushComponent.UpVector * VolumeExtent.Z;
	}

	FVector GetPlaneBottomLocation() const property
	{
		return BrushComponent.WorldLocation - BrushComponent.UpVector * VolumeExtent.Z;
	}

	void DrawFlyingVolume(FVector PointOrigin)
	{
		// First lets draw the box
		DrawBoundingBox(PointOrigin);

		for(UPrimitiveComponent Prim : BrushCollection)
		{
			if(Prim.IsA(USphereComponent::StaticClass()))
			{
				USphereComponent SphereComp = Cast<USphereComponent>(Prim);

				if(SphereComp != nullptr)
				{
					System::DrawDebugSphere(SphereComp.WorldLocation, SphereComp.SphereRadius, 32, FLinearColor::Red, 0, 30);
				}
			}
			else if(Prim.IsA(UBoxComponent::StaticClass()))
			{
				UBoxComponent BoxComp = Cast<UBoxComponent>(Prim);

				if(BoxComp != nullptr)
				{
					System::DrawDebugBox(BoxComp.WorldLocation, BoxComp.BoxExtent, FLinearColor::Red, BoxComp.WorldRotation, 0, 30);
				}
			}
			else if(Prim.IsA(UCapsuleComponent::StaticClass()))
			{
				UCapsuleComponent CapsuleComp = Cast<UCapsuleComponent>(Prim);

				if(CapsuleComp != nullptr)
				{
					System::DrawDebugCapsule(CapsuleComp.WorldLocation, CapsuleComp.CapsuleHalfHeight, CapsuleComp.CapsuleRadius, CapsuleComp.WorldRotation, FLinearColor::Red, 0, 30);
				}
			}
		}
	}

	// Test dot product of direction from Point to center of plane and its direction to determine a plane that is suitable
	bool GetClosestPlaneFromPoint(FVector Point, FVector& PlaneOrigin, FVector& PlaneNormal) const
	{
		if(IsPlaneGoodEnough(Point, PlaneForwardLocation, -BrushComponent.ForwardVector))
		{
			PlaneOrigin = PlaneForwardLocation;
			PlaneNormal = BrushComponent.ForwardVector;
			return true;
		}

		if(IsPlaneGoodEnough(Point, PlaneBackLocation, BrushComponent.ForwardVector))
		{
			PlaneOrigin = PlaneBackLocation;
			PlaneNormal = -BrushComponent.ForwardVector;
			return true;
		}

		if(IsPlaneGoodEnough(Point, PlaneRightLocation, -BrushComponent.RightVector))
		{
			PlaneOrigin = PlaneRightLocation;
			PlaneNormal = BrushComponent.RightVector;
			return true;
		}

		if(IsPlaneGoodEnough(Point, PlaneLeftLocation, BrushComponent.RightVector))
		{
			PlaneOrigin = PlaneLeftLocation;
			PlaneNormal = -BrushComponent.RightVector;
			return true;
		}

		if(IsPlaneGoodEnough(Point, PlaneUpLocation, -BrushComponent.UpVector))
		{
			PlaneOrigin = PlaneUpLocation;
			PlaneNormal = BrushComponent.UpVector;
			return true;
		}

		if(IsPlaneGoodEnough(Point, PlaneBottomLocation, BrushComponent.UpVector))
		{
			PlaneOrigin = PlaneBottomLocation;
			PlaneNormal = -BrushComponent.UpVector;
			return true;
		}

		return false;
	}

	bool IsPlaneGoodEnough(FVector Point, FVector PlaneOrigin, FVector Normal) const
	{
		const FVector DirectionToPlaneOrigin = (PlaneOrigin - Point).GetSafeNormal();
		const float Dot = DirectionToPlaneOrigin.DotProduct(Normal);
		PrintToScreen("Dot " + Dot);
		return Dot > 0.0f;
	}

	private void DrawBoundingBox(FVector PointOrigin)
	{
		const FVector VolumeCenter = BrushComponent.WorldLocation;
		const FVector Forward = BrushComponent.ForwardVector;
		const FVector Right = BrushComponent.RightVector;
		const FVector Up = BrushComponent.UpVector;

		const FVector Extents = VolumeExtent;

		const FVector PlaneForwardLoc = PlaneForwardLocation;
		const FVector PlaneBackLoc = PlaneBackLocation;
		const FVector PlaneRightLoc = PlaneRightLocation;
		const FVector PlaneLeftLoc = PlaneLeftLocation;
		const FVector PlaneUpLoc = PlaneUpLocation;
		const FVector PlaneBottomLoc = PlaneBottomLocation;

		const FRotator PlaneRotation = BrushComponent.WorldRotation;

		const FVector ForwardExtents(0, Extents.Y, Extents.Z);
		const FVector RightExtents(Extents.X, 0, Extents.Z);
		const FVector TopExtents(Extents.X, Extents.Y, 0);

		const float R = 1;
		const float G = 0;
		const float B = 0;
		float Alpha = 0;

		float ExtentsSize = Extents.SizeSquared() * 0.2f;

		if(ShouldRenderPlane(PointOrigin, Forward, PlaneForwardLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneForwardLoc, ForwardExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));

		if(ShouldRenderPlane(PointOrigin, -Forward, PlaneBackLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneBackLoc, ForwardExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(PointOrigin, Right, PlaneRightLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneRightLoc, RightExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(PointOrigin, -Right, PlaneLeftLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneLeftLoc, RightExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(PointOrigin, Up, PlaneUpLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneUpLoc, TopExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));

		if(ShouldRenderPlane(PointOrigin, -Up, PlaneBottomLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneBottomLoc, TopExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
	}

	private bool ShouldRenderPlane(FVector PointOrigin, FVector Normal, FVector PlaneOrigin, float SizeSq, float& Alpha) const
	{
		const float TargetAlpha = 0.25f;
		Alpha = 0;
		const FVector DirectionToPlane = (PlaneOrigin - PointOrigin).GetSafeNormal();
		float D = DirectionToPlane.DotProduct(Normal);

		// Render the plane if we are outside of the box.
		if(D < 0.0f)
		{
			Alpha = TargetAlpha;
			return true;
		}
			
		const FVector P = PointOrigin.ProjectOnToNormal(Normal);
		const FVector T = PlaneOrigin.ProjectOnToNormal(Normal);

		const float DistSq = T.DistSquared(P);

		if(DistSq < SizeSq)
		{
			const float Fraction = ((DistSq / SizeSq) - 1.0f) * -1.0f;
			Alpha = TargetAlpha * Fraction;
			return true;
		}

		return false;
	}
}
