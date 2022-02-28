import Vino.Audio.Footsteps.AnimNotify_Footstep;
import Cake.Environment.GPUSimulations.TextureSimulationSnowComponent;

class USnowGlobeSnowWalkingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowWalking");

	default CapabilityDebugCategory = n"SnowWalking";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UNiagaraComponent SnowFootstepsEffect;
	UTextureSimulationSnowComponent SnowSimulationComponent;

	UPROPERTY()
	UNiagaraSystem SnowEffect;

	UPROPERTY()
	UNiagaraSystem SnowStepBurstEffect;

	UPROPERTY()
	UNiagaraSystem SnowJumpBurstEffect;
	
	UPROPERTY()
	UNiagaraSystem SnowLandBurstEffect;
	
	UPROPERTY()
	TArray<UPhysicalMaterial> SnowSurfaces;
	
	UPROPERTY()
	UMaterialInterface DecalMaterial;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		//SnowSimulationComponent = UTextureSimulationSnowComponent::Get(Player); // add to sheet
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"FootstepHappened"));
		//SnowFootstepsEffect = Niagara::SpawnSystemAttached(SnowEffect, Player.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}
	
	UFUNCTION()
	void FootstepHappened(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		bool foot = FMath::RandBool();
		FVector StepLocation 	= foot ? MeshComp.GetSocketLocation(n"LeftFoot") : MeshComp.GetSocketLocation(n"RightFoot");
		FRotator StepRotation 	= foot ? MeshComp.GetSocketRotation(n"LeftFoot") : MeshComp.GetSocketRotation(n"RightFoot");
		
		if(SnowStepBurstEffect != nullptr && PlayerIsOnSnow())
		{
			//Niagara::SpawnSystemAttached(SnowStepBurstEffect, Player.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
			auto NewDecal = Gameplay::SpawnDecalAtLocation(DecalMaterial, FVector(-25, 25, 25), Player.GetActorLocation(), FRotator(90, 0, 0), 5.25f);
			NewDecal.FadeScreenSize = 0.005f;
			NewDecal.SetFadeOut(0.0f, 5.25f, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnbindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"FootstepHappened"));

		if(SnowFootstepsEffect != nullptr)
			SnowFootstepsEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
    }

	bool PlayerIsOnSnow()
	{
		if(Player == nullptr)
			return false;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		if(MoveComp == nullptr)
			return false;

		UPhysicalMaterial PhysMat = MoveComp.GetContactSurfaceMaterial();	
		if (PhysMat == nullptr)
			return false;

		bool FoundSnowSurface = false;
		for (int i = 0; i < SnowSurfaces.Num(); i++)
		{
			if(PhysMat == SnowSurfaces[i])
			{
				FoundSnowSurface = true;
				break;
			}
		}
		if(!FoundSnowSurface)
			return false;

		if(MoveComp.GroundedState != EHazeGroundedState::Grounded)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Looping effect
		//SnowFootstepsEffect.SetNiagaraVariableFloat("User.PlayerIsOnSnow", 0.0f);
		//if(PlayerIsOnSnow())
		//{
		//	SnowFootstepsEffect.SetNiagaraVariableFloat("User.PlayerIsOnSnow", 1.0f);
		//}
		//
		if(Player == nullptr)
			return;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if(MoveComp == nullptr)
			return;

		//SnowFootstepsEffect.SetNiagaraVariableFloat("User.PlayerWalking", 0.0f);
		//if(MoveComp.Velocity.SizeSquared() > 0)
		//{
		//	SnowFootstepsEffect.SetNiagaraVariableFloat("User.PlayerWalking", 1.0f);
		//}

		UPhysicalMaterial PhysMat = MoveComp.GetContactSurfaceMaterial();	
		if (PhysMat == nullptr)
			return;

		bool FoundSnowSurface = false;
		for (int i = 0; i < SnowSurfaces.Num(); i++)
		{
			if(PhysMat == SnowSurfaces[i])
			{
				FoundSnowSurface = true;
				break;
			}
		}
		if(!FoundSnowSurface)
			return;

		if(MoveComp.BecameGrounded())
		{
			//Niagara::SpawnSystemAttached(SnowLandBurstEffect, Player.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		}

		if(MoveComp.BecameAirborne())
		{
			//Niagara::SpawnSystemAttached(SnowJumpBurstEffect, Player.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}