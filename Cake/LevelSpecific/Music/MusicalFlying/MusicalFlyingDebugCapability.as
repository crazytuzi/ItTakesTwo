import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingVolume;

class UMusicalFlyingDebugCapability : UHazeDebugCapability
{
	UMusicalFlyingComponent FlyingComp;
	TArray<AMusicalFlyingVolume> ActiveFlyingVolumes;

	bool bDrawDebug = false;
	bool bDrawPhysics = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler TogleDrawDebugHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebug", "Toggle Draw Debug Flying");
		FHazeDebugFunctionCallHandler TogleInfiniteFlyingHandler = DebugValues.AddFunctionCall(n"ToggleInfiniteFlying", "Toggle Infinite Flying");

		TogleDrawDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"MusicalFlying");
		TogleInfiniteFlyingHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"MusicalFlying");
		//TogleDrawPhysicsHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"MusicalFlying");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION()
	void ToggleDrawDebug()
	{
		bDrawDebug = !bDrawDebug;

		for(AMusicalFlyingVolume FlyingVolume : ActiveFlyingVolumes)
		{
			FlyingVolume.SetActorHiddenInGame(!bDrawDebug);
		}
	}

	UFUNCTION()
	void ToggleInfiniteFlying()
	{
		FlyingComp.SetInfiniteFlying(!FlyingComp.IsInfiniteFlying());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawDebug)
		{
			DrawFlyingVolume();
			PrintToScreen("FlyingVolumes: " + FlyingComp.FlyingVolumes);
			PrintToScreen("StopFlyingVolumes: " + FlyingComp.StopFlyingVolumes);
			PrintToScreen("InfinitFlying: " + FlyingComp.IsInfiniteFlying());
		}
	}

	private void DrawFlyingVolume()
	{
		FlyingComp.GetAllActiveFlyingVolumes(ActiveFlyingVolumes);

		for(AMusicalFlyingVolume FlyingVolume : ActiveFlyingVolumes)
		{
			FlyingVolume.DrawFlyingVolume(Owner.ActorLocation);
		}
		/*
		AMusicalFlyingVolume FlyingVolume;// = Cast<AMusicalFlyingVolume>(FlyingComp.FlyingVolume);

		if(FlyingVolume == nullptr)
			return;

		const FVector VolumeCenter = FlyingVolume.BrushComponent.WorldLocation;
		const FVector Forward = FlyingVolume.BrushComponent.ForwardVector;
		const FVector Right = FlyingVolume.BrushComponent.RightVector;
		const FVector Up = FlyingVolume.BrushComponent.UpVector;

		const FVector Extents = FlyingVolume.VolumeExtent;

		const FVector PlaneForwardLoc = FlyingVolume.PlaneForwardLocation;
		const FVector PlaneBackLoc = FlyingVolume.PlaneBackLocation;
		const FVector PlaneRightLoc = FlyingVolume.PlaneRightLocation;
		const FVector PlaneLeftLoc = FlyingVolume.PlaneLeftLocation;
		const FVector PlaneUpLoc = FlyingVolume.PlaneUpLocation;
		const FVector PlaneBottomLoc = FlyingVolume.PlaneBottomLocation;

		const FRotator PlaneRotation = FlyingVolume.BrushComponent.WorldRotation;

		const FVector ForwardExtents(0, Extents.Y, Extents.Z);
		const FVector RightExtents(Extents.X, 0, Extents.Z);
		const FVector TopExtents(Extents.X, Extents.Y, 0);

		const float R = 1;
		const float G = 0;
		const float B = 0;
		float Alpha = 0;

		float ExtentsSize = Extents.SizeSquared() * 0.2f;


		if(ShouldRenderPlane(Forward, PlaneForwardLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneForwardLoc, ForwardExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));

		if(ShouldRenderPlane(-Forward, PlaneBackLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneBackLoc, ForwardExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(Right, PlaneRightLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneRightLoc, RightExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(-Right, PlaneLeftLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneLeftLoc, RightExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
		
		if(ShouldRenderPlane(Up, PlaneUpLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneUpLoc, TopExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));

		if(ShouldRenderPlane(-Up, PlaneBottomLoc, ExtentsSize, Alpha))
			Debug::DrawSolidBox(PlaneBottomLoc, TopExtents, PlaneRotation, FLinearColor(R, G, B, Alpha));
			*/
	}

	bool ShouldRenderPlane(FVector Normal, FVector PlaneOrigin, float SizeSq, float& Alpha) const
	{
		const float TargetAlpha = 0.25f;
		Alpha = 0;
		const FVector OwnerLocation = Owner.ActorLocation;
		const FVector DirectionToPlane = (PlaneOrigin - OwnerLocation).GetSafeNormal();
		float D = DirectionToPlane.DotProduct(Normal);

		// Render the plane if we are outside of the box.
		if(D < 0.0f)
		{
			Alpha = TargetAlpha;
			return true;
		}
			
		const FVector P = OwnerLocation.ProjectOnToNormal(Normal);
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
