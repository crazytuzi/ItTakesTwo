const FConsoleVariable AutoAimDebug("Haze.AutoAimDebug", DefaultValue = 0);
const FConsoleVariable AutoAimStrength("Haze.AutoAimStrength", DefaultValue = 1.f);

// Component on the player that tracks all relevant auto aim targets
UCLASS(NotPlaceable, NotBlueprintable)
class UAutoAimComponent : UActorComponent
{
    TArray<UAutoAimTargetComponent> AutoAimTargets;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		// Auto aim target component only lists actors in the level,
		// we should not reset ourselves but stay persistent
		Reset::RegisterPersistentComponent(this);
	}
};

// Singular actor for an unconnected auto-aim target in the level
UCLASS(HideCategories = "Rendering Activation Cooking Input Actor LOD")
class AAutoAimTarget : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UAutoAimTargetComponent AutoAimTarget;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
       	auto EditorSprite = UBillboardComponent::Create(this);
		EditorSprite.bIsEditorOnly = true;
        EditorSprite.SetSprite(Asset("Texture2D'/Game/Editor/EditorBillboards/AutoAimTarget.AutoAimTarget'"));
    }
};

// Component used for auto-aim that can be placed on any actor
UCLASS(HideCategories = "Activation Tags Physics LOD AssetUserData Collision")
class UAutoAimTargetComponent : USceneComponent
{
    /* Determines if we should use the actor bounds as target radius
        instead of providing our own. */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay)
    bool bUseActorBoundsAsRadius = false;

    /**
	 * If set, we ignore the attach parent of the auto aim component
	 * when doing a trace to check whether the auto aiming is blocked by
	 * anything. You normally want this on, because the thing you're
	 * auto-aiming at should not block auto-aiming.
	 */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay)
    bool bIgnoreParentForAutoAimTraceBlock = true;

    /* The area that we want to be aiming at.
       Any point in this area is considered fully correctly aimed. */
    UPROPERTY(Category = "Auto Aim", Meta = (EditCondition = "!bUseActorBoundsAsRadius", EditConditionHides))
    float TargetRadius = 35.f;

    /**
	 * You can use this to prioritize this component over others
	 */
	UPROPERTY(Category = "Auto Aim", AdvancedDisplay)
	float BonusScore = 0;

    UFUNCTION(BlueprintPure)
    float CalculateTargetRadius()
    {
        if (bUseActorBoundsAsRadius)
        {
            // Calculate radius from actor bounds
            FVector Origin;
            FVector Bounds;
            GetOwner().GetActorBounds(false, Origin, Bounds);

            // Radius will be the bounds's maximum element (since the sphere has to encapsulate that point at most)
            return Bounds.Max;
        }
        else
        {
            return TargetRadius;
        }
    }

	/**
	 * If set, the 'AutoAimMaxAngle' will change.
	 * At the 'MinimumDistance' the min 'AutoAimMaxAngleMinDistance' is used
	 * At the 'MaximumDistance' the max 'AutoAimMaxAngleAtMaxDistance' is used
	 */
	UPROPERTY(Category = "Auto Aim")
	bool bUseVariableAutoAimMaxAngle = false;

    /* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
    UPROPERTY(Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    float AutoAimMaxAngle = 3.f;
	
	/* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
	UPROPERTY(Category = "Auto Aim", Meta = (EditCondition = "bUseVariableAutoAimMaxAngle", EditConditionHides))
	float AutoAimMaxAngleMinDistance = 3.f;

	 /* The maximum angle that the auto-aim can modify the original trajectory by.
       Specified in degrees. */
	UPROPERTY(Category = "Auto Aim", Meta = (EditCondition = "bUseVariableAutoAimMaxAngle", EditConditionHides))
	float AutoAimMaxAngleAtMaxDistance = 3.f;

	UFUNCTION(BlueprintPure)
    float CalculateAutoAimMaxAngle(float CurrentMinDistance, float CurrentMaxDistance, float CurrentDistance, float ConfigStrength = 1.f)
	{
		if(!bUseVariableAutoAimMaxAngle)
			return AutoAimMaxAngle * ConfigStrength;
		
		float MinDistToUse = CurrentMinDistance;
		if (bOverrideMinimumDistance)
			MinDistToUse = MaximumDistance;

		float MaxDistToUse = CurrentMaxDistance;
		if (bOverrideMaximumDistance)
			MaxDistToUse = MaximumDistance;

		const float DistanceAlpha = FMath::Clamp(CurrentDistance - MinDistToUse, 0.f, MaxDistToUse) / MaxDistToUse;
		return FMath::Lerp(AutoAimMaxAngleMinDistance, AutoAimMaxAngleAtMaxDistance, DistanceAlpha) * ConfigStrength;
	}

    /* Only the selected players will be able to use this auto aim target. */
    UPROPERTY(BlueprintReadOnly, Category = "Auto Aim")
    EHazeSelectPlayer AffectsPlayers = EHazeSelectPlayer::Both;

    /* Using interpolated auto-aim, we aim at a point in the target radius relative to where we aimed
       in the auto-aim radius. Without it, auto-aim will always aim at the outer border of the target area. */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay)
    bool bUseInterpolatedAutoAim = true;

	/* Specifies if this is enabled or not, so your can turn it off if, for example, an actor dies but doesn't get removed from the scene */
	UPROPERTY(BlueprintReadOnly, Category = "Auto Aim")
	bool bIsAutoAimEnabled = true;

	/* How much weight is assigned to the target distance compared to the auto aim angle. */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay)
    float TargetDistanceWeight = 0.5f;

    UPROPERTY(Category = "Auto Aim", AdvancedDisplay, Meta = (InlineEditConditionToggle))
    bool bOverrideMinimumDistance = false;

	/* Override the weapon's minimum auto aim distance for this specific point. */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay, Meta = (EditCondition = bOverrideMinimumDistance))
    float MinimumDistance = 0.f;

    UPROPERTY(Category = "Auto Aim", AdvancedDisplay, Meta = (InlineEditConditionToggle))
    bool bOverrideMaximumDistance = false;

	/* Override the weapon's maximum auto aim distance for this specific point. */
    UPROPERTY(Category = "Auto Aim", AdvancedDisplay, Meta = (EditCondition = bOverrideMaximumDistance))
    float MaximumDistance = 1000.f;

	UFUNCTION(Category = "Auto Aim")
	void SetAutoAimEnabled(bool bEnabled)
	{
		bIsAutoAimEnabled = bEnabled;
	}

	UFUNCTION(Category = "Auto Aim")
	void ChangeAffectedPlayers(EHazeSelectPlayer NewAffects)
	{
		for (auto Player : Game::Players)
		{
			if (Player == nullptr)
				continue;

			auto Component = UAutoAimComponent::Get(Player);
			if (Player.IsSelectedBy(AffectsPlayers) && !Player.IsSelectedBy(NewAffects))
				Component.AutoAimTargets.RemoveSwap(this);
			else if (!Player.IsSelectedBy(AffectsPlayers) && Player.IsSelectedBy(NewAffects))
				Component.AutoAimTargets.Add(this);
		}

		AffectsPlayers = NewAffects;
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        for (auto Player : Game::GetPlayersSelectedBy(AffectsPlayers))
        {
            auto Component = UAutoAimComponent::GetOrCreate(Player);
            Component.AutoAimTargets.Add(this);
        }
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        for (auto Player : Game::GetPlayersSelectedBy(AffectsPlayers))
        {
			if (Player == nullptr)
				continue;

            auto Component = UAutoAimComponent::Get(Player);
			if (Component != nullptr)
				Component.AutoAimTargets.RemoveSwap(this);
        }
    }

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		bIsAutoAimEnabled = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		// Not that nice, we should really have a set of disablers instead
		bIsAutoAimEnabled = true;
	}

	bool PlayerCanTarget(AHazePlayerCharacter Player)const
	{
		if(!bIsAutoAimEnabled)
			return false;
		
		if(Player == nullptr)
			return false;

		if(AffectsPlayers == EHazeSelectPlayer::Both)
			return true;

		if(AffectsPlayers == EHazeSelectPlayer::None)
			return false;

		if(AffectsPlayers == EHazeSelectPlayer::Cody)
			return Player.IsCody();

		if(AffectsPlayers == EHazeSelectPlayer::May)
			return Player.IsMay();

		return true;
	}

#if !RELEASE
   	void ShowDebug(AHazePlayerCharacter FromPlayerPlayer, float CalulcatedMaxAngle, float Distance) 
    {
        if (AutoAimDebug.GetInt() == 0)
            return;

		if (bIsAutoAimEnabled == false)
			return;

        if (FromPlayerPlayer == nullptr)
            return;

		if(!FromPlayerPlayer.HasControl())
			return;

        float Radius = FMath::Tan(FMath::DegreesToRadians(CalulcatedMaxAngle)) * Distance;
        System::DrawDebugSphere(WorldLocation, Radius, LineColor = FLinearColor::Blue);
    }
#endif
};

#if EDITOR
class UAutoAimTargetVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UAutoAimTargetComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UAutoAimTargetComponent AimComp = Cast<UAutoAimTargetComponent>(Component);
		
		// happens on teardown on the dummy component
		if(AimComp == nullptr)
			return;

        if (AimComp.GetOwner() == nullptr)
            return;

        if (AimComp.TargetRadius == 0.f)
            DrawPoint(AimComp.WorldLocation, FLinearColor::Green, 20.f);
        else
            DrawWireSphere(AimComp.WorldLocation, AimComp.TargetRadius, Color = FLinearColor::Green);

        FVector EditorCamera = Editor::GetEditorViewLocation();
        float Distance = EditorCamera.Distance(AimComp.WorldLocation);

        float Radius = FMath::Tan(FMath::DegreesToRadians(AimComp.CalculateAutoAimMaxAngle(0.f, 10000.f, Distance, AutoAimStrength.GetFloat()))) * Distance;
        DrawWireSphere(AimComp.WorldLocation, Radius, Color = FLinearColor::Blue);
    }   
} 
#endif