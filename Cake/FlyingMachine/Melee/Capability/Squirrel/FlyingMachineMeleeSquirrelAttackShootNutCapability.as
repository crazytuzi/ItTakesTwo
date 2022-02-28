
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;
import Cake.FlyingMachine.Melee.AnimNotify.AnimNotify_MeleeSquirrelShootNut;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeNutComponent;

class UFlyingMachineMeleeSquirrelAttackShootNutCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);
	default CapabilityTags.Add(MeleeTags::MeleeAttack);
	default CapabilityTags.Add(MeleeTags::MeleeAttackNormal);
	default CapabilityTags.Add(MeleeTags::MeleeAttackNormal);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default CapabilityDebugCategory = MeleeTags::Melee;
	default TickGroupOrder = 50;

	// InternalParams
	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	// float TimeToFlyDuration = 0;
	// float TimeToFlyInitialDuration = 0;

	TArray<AFlyingMachineMeleeNut> Nuts;
	int CurrentActiveNutIndex = 0;
	bool bHasShotNut = false;
	bool bHasActivated = false;
	float ShowMeshTimeLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
		Squirrel = Cast<AHazeCharacter>(Owner);

		for(int i = 0; i < 3; ++i)
		{
			AFlyingMachineMeleeNut Nut = Cast<AFlyingMachineMeleeNut>(SpawnActor(SquirrelMeleeComponent.NutType, bDeferredSpawn = true, Level = Squirrel.GetLevel()));
			if(Nut != nullptr)
			{
				Nut.MakeNetworked(this, i);
				FinishSpawningActor(Nut);

				Nuts.Add(Nut);
				UHazeMelee2DComponent NutComponent = UHazeMelee2DComponent::Get(Nut);
				Nut.SetOwner(Owner);
				AddChildToFight(Nut);
				Nut.DisableActor(nullptr);
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SquirrelMeleeComponent.RemoveChildsFromFight();
		for(AFlyingMachineMeleeNut Nut : Nuts)
		{
			if(Nut != nullptr)
			{
				Nut.DestroyActor();
			}
		}
		Nuts.Empty();
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!SquirrelMeleeComponent.HasPendingAttackShootNut())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsStateActive(EHazeMeleeStateType::Attack))
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;

		if(SquirrelMeleeComponent.CurrentNut == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		SquirrelMeleeComponent.PendingActivationData.Consume(ActivationParams);

		FHazeMeleeTarget PlayerTarget;
		if(MeleeComponent.GetCurrentTarget(PlayerTarget))
		{
			// Force the squirrel to face the correct way
			if(PlayerTarget.bIsToTheRightOfMe)
				FaceRight();
			else
				FaceLeft();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		// This will reset the other attack capability
		SetMutuallyExclusive(MeleeTags::MeleeAttack, true);
		SetMutuallyExclusive(MeleeTags::MeleeAttack, false);

		ConsumeAction(MeleeTags::MeleeShootNut);

		FMeleePendingControlData AttackData;
		AttackData.Receive(ActivationParams);
		ActivateState(EHazeMeleeStateType::Attack, AttackData.Feature, AttackData.ActionType);

		SquirrelMeleeComponent.CurrentNut = Nuts[CurrentActiveNutIndex];
		CurrentActiveNutIndex++;
		if(CurrentActiveNutIndex >= Nuts.Num())
			CurrentActiveNutIndex = 0;

		SquirrelMeleeComponent.CurrentNut.MoveTime = 0;
		SquirrelMeleeComponent.CurrentNut.bHasImpactedWithTarget = false;
		SquirrelMeleeComponent.CurrentNut.bIsAttached = true;
		SquirrelMeleeComponent.CurrentNut.EnableActor(nullptr);
		SquirrelMeleeComponent.CurrentNut.AttachToComponent(Squirrel.Mesh, n"Align", EAttachmentRule::SnapToTarget);
		SquirrelMeleeComponent.CurrentNut.RootComponent.SetRelativeTransform(FTransform::Identity);

		auto NutComponent = UHazeMelee2DComponent::Get(SquirrelMeleeComponent.CurrentNut);
		NutComponent.EnableAttachment();
		SquirrelMeleeComponent.CurrentNut.AttachToComponent(Squirrel.Mesh, n"Align", EAttachmentRule::SnapToTarget);

		auto NutMesh = SquirrelMeleeComponent.CurrentNut.GetNutMesh();
		NutMesh.SetRelativeTransform(FTransform::Identity);
		NutMesh.SetHiddenInGame(true);
		ShowMeshTimeLeft = FMath::Max(KINDA_SMALL_NUMBER, SquirrelMeleeComponent.CurrentNut.ShowModelAfterActivationEffectDelay);
				
		auto ActivationEffect = SquirrelMeleeComponent.CurrentNut.ActivationEffect;			
		ActivationEffect.Deactivate();
		ActivationEffect.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!bHasShotNut)
			SquirrelMeleeComponent.DeactivateNut();

		bHasShotNut = false;
		bHasActivated = false;
		DeactivateState(EHazeMeleeStateType::Attack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// The nut can impact the player while beeing constructed
		MeleeComponent.UpdateControlSideImpact();

		if(SquirrelMeleeComponent.CurrentNut != nullptr)
		{
			if(!bHasActivated)
			{
				const EActionStateStatus ShouldActivate = ConsumeAction(MeleeTags::MeleeActivateNut);
				if(ShouldActivate == EActionStateStatus::Active)
				{
					bHasActivated = true;
					auto ActivationEffect = SquirrelMeleeComponent.CurrentNut.ActivationEffect;
					ActivationEffect.Activate(true);
					ActivationEffect.SetHiddenInGame(false);
				}
			}
			else if(ShowMeshTimeLeft > 0)
			{
				ShowMeshTimeLeft -= DeltaTime;
				if(ShowMeshTimeLeft <= 0)
				{
					auto NutMesh = SquirrelMeleeComponent.CurrentNut.GetNutMesh();
					auto ActivationEffect = SquirrelMeleeComponent.CurrentNut.ActivationEffect;
					NutMesh.SetHiddenInGame(false);
					ActivationEffect.Deactivate();
					ActivationEffect.SetHiddenInGame(true);
				}
			}

			if(HasControl() && !bHasShotNut)
			{	
				const EActionStateStatus ShouldShoot = ConsumeAction(MeleeTags::MeleeShootNut);
				if(ShouldShoot == EActionStateStatus::Active)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddObject(n"Nut", SquirrelMeleeComponent.CurrentNut);
					if(IsFacingRight())
						CrumbParams.AddActionState(n"FaceRight");
					UHazeCrumbComponent::Get(Owner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ReleaseNut"), CrumbParams);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ReleaseNut(const FHazeDelegateCrumbData& CrumbData)
	{
		if(IsActive())
		{
			ShowMeshTimeLeft = 0;
			bHasShotNut = true;
		}

		auto WantedNut = Cast<AFlyingMachineMeleeNut>(CrumbData.GetObject(n"Nut"));
		if(WantedNut == SquirrelMeleeComponent.CurrentNut && SquirrelMeleeComponent.CurrentNut != nullptr)
			ReleaseNut(CrumbData.GetActionState(n"FaceRight"));	
	}

	void ReleaseNut(bool bFaceRight)
	{
		auto NutMeleeComponent = UFlyingMachineMeleeNutComponent::Get(SquirrelMeleeComponent.CurrentNut);
		auto NutMesh = SquirrelMeleeComponent.CurrentNut.GetNutMesh();
		auto ActivationEffect = SquirrelMeleeComponent.CurrentNut.ActivationEffect;

		// Setup movement params
		SquirrelMeleeComponent.CurrentNut.bIsAttached = false;
		FVector WantedLocation = NutMesh.GetWorldLocation();

		auto NutComponent = UFlyingMachineMeleeNutComponent::Get(SquirrelMeleeComponent.CurrentNut);
		NutComponent.EnableAttachment();
		
		SquirrelMeleeComponent.CurrentNut.SetActorLocation(WantedLocation);
		NutMesh.AttachToComponent(SquirrelMeleeComponent.CurrentNut.Root, NAME_None, EAttachmentRule::SnapToTarget);
		NutMesh.SetHiddenInGame(false);
		ActivationEffect.Deactivate();
		ActivationEffect.SetHiddenInGame(true);
		FVector MeshSize = Owner.GetActorRelativeScale3D();
		NutMesh.SetWorldScale3D(MeshSize); 
		NutMesh.RelativeLocation = FVector::ZeroVector;
		if(!bFaceRight)
		{
			NutMesh.RelativeRotation = FRotator(0.f, -90.f + 180.f, 0.f);
		}
		else
		{
			NutMesh.RelativeRotation = FRotator(0.f, 90.f + 180.f, 0.f);
		}
	}
}
