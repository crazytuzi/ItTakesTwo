import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.WingedPackage.WingedPackage;

class UWingedPackagePlayerCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::PlayerWingedPackageFlight);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	default CapabilityDebugCategory = n"LevelSpecific";

	AWingedPackage Package;
	AHazePlayerCharacter Player;
	UHazeCrumbComponent CrumbComponent;

	FHazeCrumbDelegate CrumbDelegate;

	int FlapsInAir = 0;
	UPROPERTY()
	bool bIsInGlideState = false;

	bool bHoldingJump = false;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);	
		CrumbComponent = UHazeCrumbComponent::Get(Player);
		CrumbDelegate.BindUFunction(this, n"PerformFlap");
	}

	UFUNCTION()
	bool GetIsPlayercarryingWingedPackage() const property
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::GetOrCreate(Player);
		AWingedPackage CurrentPickupPackage = Cast<AWingedPackage>(PickupComp.CurrentPickup);

		if(CurrentPickupPackage != nullptr)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsPlayercarryingWingedPackage)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsPlayercarryingWingedPackage)
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}

		else
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
	}
	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::GetOrCreate(Player);
		Package = Cast<AWingedPackage>(PickupComp.CurrentPickup);
		FlapsInAir = 0;

		if(!ActivationParams.IsStale())
		{
			if (WasActioning(MovementSystemTags::Grinding, 0.1f))
			{
				MoveComp.AddImpulse(FVector::UpVector * 2000, n"Flap");

				CrumbComponent.LeaveAndTriggerDelegateCrumb(CrumbDelegate, FHazeDelegateCrumbParams());
			}
		}
	}

	UFUNCTION()
	void PerformFlap(const FHazeDelegateCrumbData& CrumbData)
	{
		FVector Velocity = MoveComp.Velocity;
		Velocity.Z = 0;
		MoveComp.Velocity = Velocity;
		MoveComp.Velocity += Player.ActorForwardVector * 0.55f * MoveComp.Velocity.Size();
		MoveComp.AddImpulse(FVector::UpVector * 2000, n"Flap");

		ClampMoveSpeed();

		FlapsInAir++;
		Package.FlapWings();
	}

	void GlideUpdate()
	{
		UMovementSettings::SetGravityMultiplier(Player, 0.2f, this);

		if (MoveComp.Velocity.Size() < 2800.f)
		{
			MoveComp.AddImpulse(Player.ActorForwardVector * 30, n"Glide");
		}

		ClampMoveSpeed();
	}

	void ClampMoveSpeed()
	{
		MoveComp.Velocity = MoveComp.Velocity.GetClampedToMaxSize(3000.f);
	}

	void ApplyWindForce()
	{
		FVector WingedPackageWindForce = GetAttributeVector(n"WingedPackageWindForce");

		if (WingedPackageWindForce.Size() != 0)
		{
			MoveComp.AddImpulse(WingedPackageWindForce, n"Flap");
		}
	}


	UFUNCTION(NetFunction)
	void NetSetGlideState(bool GlideState)
	{
		Package.SetGlideState(GlideState);
		bIsInGlideState = GlideState;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.IsGrounded() && IsActioning(ActionNames::MovementJump))
		{
			if(!bHoldingJump && FlapsInAir != 3)
			{
				CrumbComponent.LeaveAndTriggerDelegateCrumb(CrumbDelegate, FHazeDelegateCrumbParams());
				bHoldingJump = true;
			}

			else if (MoveComp.Velocity.Z < 0)
			{
				if (!bIsInGlideState && HasControl())
				{
					NetSetGlideState(true);
				}

				GlideUpdate();
			}
		}

		else
		{
			bHoldingJump = false;
			UMovementSettings::ClearGravityMultiplier(Player, this);

			if (bIsInGlideState && HasControl())
			{
				NetSetGlideState(false);	
			}
		}

		if (!MoveComp.IsGrounded())
		{
			ApplyWindForce();
		}

		if (MoveComp.IsGrounded())
		{
			FlapsInAir = 0;
			Package.bIsGrounded = true;
		}

		else
		{
			Package.bIsGrounded = false;
		}

		Package.SetGlideState(bIsInGlideState);
	}
}
