import Cake.LevelSpecific.SnowGlobe.SnowyOwl.SnowyOwl;

class ASnowyOwlManager : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/WindManager.WindManager");
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

	UPROPERTY(Category = "Manager")
	TArray<ASnowyOwl> Owls;

	UPROPERTY(Category = "Manager")
	float AvoidanceRadiusScale = 0.6f;

	UPROPERTY(Category = "Manager")
	float AvoidanceSpeedModifier = 0.3f;
	
	UPROPERTY(Category = "Manager")
	float StaticMoveRate = 1.f / 30.f;

	UFUNCTION(CallInEditor, Category = "Manager")
	void FindInLevel()
	{
		GetAllActorsOfClass(Owls);
		for (int i = Owls.Num() - 1; i >= 0; --i)
		{
			if (Owls[i].Level != Level)
				Owls.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Remove lost references
		for (int i = Owls.Num() - 1; i >= 0; --i)
		{
			if (Owls[i] == nullptr)
				Owls.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0; i < Owls.Num(); ++i)
		{
			auto Owl = Owls[i];

			if (!CanMove(Owl))
				continue;

			// Move out of overlaps, happens when the owls are disabled on top of eachother
			// or post-transition between splines
			for (int j = i + 1; j < Owls.Num(); ++j)
			{
				auto Other = Owls[j];

				if (IsOverlapping(Owl, Other))
				{
					// Speed up leading, slow down follower
					if (Owl.MovementComp.Distance >= Other.MovementComp.Distance)
					{
						Owl.MovementComp.AvoidanceModifier += AvoidanceSpeedModifier;
						Other.MovementComp.AvoidanceModifier -= AvoidanceSpeedModifier;
					}
					else
					{
						Owl.MovementComp.AvoidanceModifier -= AvoidanceSpeedModifier;
						Other.MovementComp.AvoidanceModifier += AvoidanceSpeedModifier;
					}
				}
			}

			// Moves custom transform, without applying to actor
			Owl.MovementComp.Move(DeltaTime);

			bool bForceAnimated = Owl.HasAttachedPlayers();
			Owl.VisibilityComp.UpdateVisibility(bForceAnimated);

			// Apply custom transform to actor
			if (CanApplyMove(Owl))
				Owl.MovementComp.ApplyMove(DeltaTime);

			// Consume avoidance modifier, set on a per-frame basis
			Owl.MovementComp.AvoidanceModifier = 0.f;
		}
	}

	bool IsOverlapping(ASnowyOwl First, ASnowyOwl Second)
	{
		if (First == nullptr ||
			Second == nullptr || 
			Second.MovementComp.CurrentSpline != First.MovementComp.CurrentSpline)
			return false;

		float FirstDistance = First.MovementComp.Distance;
		float SecondDistance = Second.MovementComp.Distance;
		float AvoidanceRadius = (First.Mesh.BoundsRadius + Second.Mesh.BoundsRadius) * AvoidanceRadiusScale;

		if (!FMath::IsWithin(FirstDistance, SecondDistance - AvoidanceRadius, SecondDistance + AvoidanceRadius))
			return false;

		return true;
	}

	bool CanMove(ASnowyOwl Owl)
	{
		if (Owl == nullptr)
			return false;

		if (Owl.IsActorDisabled())
			return false;

		if (Owl.IsActorBeingDestroyed())
			return false;

		if (!Owl.MovementComp.CanMove())
			return false;

		return true;
	}

	bool CanApplyMove(ASnowyOwl Owl)
	{
		if (Owl.VisibilityComp.IsAnimated())
			return true;

		if (Time::GetGameTimeSince(Owl.MovementComp.LastAppliedMove) >= StaticMoveRate)
			return true;

		return false;
	}

	UFUNCTION()
	void EnableOwls()
	{
		if (HasControl())
			NetEnableOwls();
	}

	UFUNCTION(NetFunction)
	void NetEnableOwls()
	{
		for (auto Owl : Owls)
			Owl.EnableSnowyOwl();
	}

	UFUNCTION(DevFunction)
	void DevToggleSnowyOwls()
	{
		for (auto Owl : Owls)
			Owl.EnableSnowyOwl();
	}
}