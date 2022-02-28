import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

class UClockworkBullBossDebugWidget : UHazeUserWidget
{
	UPROPERTY()
	FString CurrentDebugText;
}

class UClockworkBullBossDebugCapability : UHazeDebugCapability
{
	UPROPERTY()
	TSubclassOf<UClockworkBullBossDebugWidget> DebugWidgetClass;

	UClockworkBullBossDebugWidget DebugWidget;
	AClockworkBullBoss BullOwner;

	FString BullText;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        BullOwner = Cast<AClockworkBullBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsFlag(n"BullBossDebug", "Show Bullboss debug info");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		BullText = "";
		BullOwner.ConsumeDebugText(DeltaTime, BullText);
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Owner.GetDebugFlag(n"BullBossDebug"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

    /* Checks if the Capability should deactivate and stop ticking
    *  Will be called every tick when the capability is activate and before it ticks. The Capability will not tick the same frame as DeactivateLocal or DeactivateFromControl is returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Owner.GetDebugFlag(n"BullBossDebug"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DebugWidget = Cast<UClockworkBullBossDebugWidget>(Widget::AddFullscreenWidget(DebugWidgetClass));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget::RemoveFullscreenWidget(DebugWidget);
		DebugWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FString& DBText = DebugWidget.CurrentDebugText;
		DBText = "";

		if(HasControl())
		{
			DBText = "CONTROL SIDE\n\n";
		}

		FHazeFrameMovement DebugData;
		FHazeRequestLocomotionData AnimationRequest;
		if(BullOwner.GetPendingDebugMovementData(DebugData, AnimationRequest))
		{
			DBText += "\n";
			DBText += "Instigator: ";
			DBText += DebugData.Instigator;

			DBText += "\n";
			DBText += "Animation: ";

			if(AnimationRequest.AnimationTag == n"Movement")
				DBText += "<Blue>";
			else if(AnimationRequest.AnimationTag == n"Attack")
				DBText += "<Red>";
			else if(AnimationRequest.AnimationTag == n"Charge")
				DBText += "<Yellow>";

			DBText += AnimationRequest.AnimationTag;
			DBText += "</>";

			if(AnimationRequest.AnimationTag == n"Charge")
			{
				DBText += " [ <Yellow>";
				FString EnumStrin = "" + BullOwner.ChargeState;
				EnumStrin.RemoveFromStart("EBullBossChargeStateType::");
				DBText += EnumStrin;
				DBText += " </>]";
			}

			FVector DebugLocation;
			if(AnimationRequest.GetWantedWorldLocation(DebugLocation))
			{
				FLinearColor DebugColor = FLinearColor::LucBlue;
				System::DrawDebugCircle(DebugLocation + FVector(0.f, 0.f, 10.f), 100, LineColor = DebugColor, YAxis = FVector::RightVector, ZAxis = FVector::ForwardVector);
				System::DrawDebugArrow(DebugLocation + FVector(0.f, 0.f, 1000.f), DebugLocation, 55, LineColor = DebugColor, Thickness = 6.f);
			}
		}
		
		// Root motion
		DBText += "\n";
		DBText += "RootMotion Rotation: ";
		const float BlendAlpha = BullOwner.GetRootMotionBlendAlpha();
		const bool bRootMotionRotationActive = BullOwner.IsRootMotionRotationActive();
		if(BlendAlpha > 0)
		{
			if(!bRootMotionRotationActive)
			{
				DBText += "<Green>Enabled</> blending in: " + BlendAlpha;
			}
			else
			{
				DBText += "<Green>Disabled blending in:</>" + BlendAlpha;
			}		
		}
		else if(bRootMotionRotationActive)
		{
			DBText += "<Green>Enabled</>";
		}
		else
		{
			DBText += "<Red>Disabled</>";
		}

		DBText += "\n\n";

		// Attacks
		DBText += "Can See Target: ";
		DBText += BullOwner.Settings.CanSeeTargetRange;
		DBText += " |: ";
		DBText += BullOwner.Settings.CanSeeTargetAngle;
		if(BullOwner.AttackRangeChange.IncreasedAttackRange != 0)
		{
			DBText += "\nIncrease by: " + BullOwner.AttackRangeChange.IncreasedAttackRange + " for: " + BullOwner.AttackRangeChange.IncreasedAttackRangeDuration;
		}

		DBText += "\n\n";
		DBText += BullText;

		// Draw debug shapes
		for(const FBullAttackCollisionData& collision : BullOwner.CollisionData)
		{
			if(collision.CollisionComponent == nullptr)
				continue;
				
			FLinearColor Color = FLinearColor::Gray;
			if(collision.IsCollisionEnabled())
				Color = FLinearColor::Red;

			FVector2D Size = collision.GetCollisionSize();
			if(Size.Y > 0)
			{
				FHazeIntersectionCapsule Capsule = collision.GetCapsule();
				System::DrawDebugCapsule(Capsule.Origin, Size.Y, Size.X, Capsule.Rotation, LineColor = Color);
			}
			else
			{
				FHazeIntersectionSphere Sphere = collision.GetSphere();
				System::DrawDebugSphere(Sphere.Origin, Size.X, 8, LineColor = Color);
			}
		}
	}
}