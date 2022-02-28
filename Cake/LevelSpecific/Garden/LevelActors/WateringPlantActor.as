import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.ActivationPoint.DummyActivationPoint;

event void FOnWateringPlantFinished();
event void FOnWateringStarted();
event void FOnWateringStopped();

UCLASS(Abstract)
class AWateringPlantActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UHazeSkeletalMeshComponentBase HazeSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent WaterCollider;

	UPROPERTY(DefaultComponent, Attach = WaterCollider)
	UWaterHoseImpactComponent WaterHoseComp;

	UPROPERTY(DefaultComponent, Attach = WaterHoseComp)
	UDummyActivationPointBase DummyWaterComp;
	default DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent VineCollider;

	UPROPERTY(DefaultComponent, Attach = VineCollider)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UDummyActivationPointBase DummyVineComp;
	default DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent, Attach = VineCollider)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartIdleEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopIdleEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Events")
	FOnWateringPlantFinished OnWateringPlantFinished;
	UPROPERTY(Category = "Events")
	FOnWateringStarted OnWateringStarted;
	UPROPERTY(Category = "Events")
	FOnWateringStopped OnWateringStopped;

	UPROPERTY(EditDefaultsOnly)
	bool bIsDoubleInteractFlower = false;
	UPROPERTY(EditDefaultsOnly)
	bool bFinishWhenFullyWatered = true;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bDisableCollisionOnWatered = false;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bIsLogSectionVariant = false;

	UPROPERTY(NotEditable)
	bool bIsMayInRangeOfLogVariant = false;
	
	UPROPERTY()
	bool bUsesElderMeshVariant = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bIsDecaying = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bIsFinished = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bIsDrinking = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bIsAttached = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bIsOpen = false;

	UPROPERTY(NotEditable, Category = "Animation Data")
	float WaterAmount = 0.0f;

	UPROPERTY(NotEditable, Category = "Animation Data")
	FVector PlayerPosition = FVector::ZeroVector;

	UPROPERTY(NotEditable, Category = "Animation Data")
	FRotator LookAtPlayerRotation = FRotator::ZeroRotator;

	//""NOT FULLY IMPLEMENTED YET"""
	UPROPERTY(NotEditable, Category = "Animation Data")
	bool bUseLookAtCodyPosition = false;

	UPROPERTY(Category = "Animation Data")
	bool bAttachWaterImpactComponent = true;

	UPROPERTY(Category = "Settings")
	bool bUseDummyVineIcon = false;

	UPROPERTY(Category = "Settings")
	bool bUseDummyWaterIcon = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DummyVineComp.InitializeDistances(VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Visible),
											 VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Targetable),
												 VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Selectable));
		
		DummyWaterComp.InitializeDistances(WaterHoseComp.GetDistance(EHazeActivationPointDistanceType::Visible),
												 WaterHoseComp.GetDistance(EHazeActivationPointDistanceType::Targetable),
													 WaterHoseComp.GetDistance(EHazeActivationPointDistanceType::Selectable));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VineCollider.AttachToComponent(HazeSkelMeshComp, n"Hook2", EAttachmentRule::SnapToTarget);

		if(bAttachWaterImpactComponent)
			WaterCollider.AttachToComponent(HazeSkelMeshComp, n"Pitcher", EAttachmentRule::KeepWorld);

		HazeAkComp.HazePostEvent(StartIdleEvent);

		if(bIsDoubleInteractFlower)
		{
			WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

			VineImpactComp.OnVineConnected.AddUFunction(this, n"OnVineAttached");
			VineImpactComp.OnVineDisconnected.AddUFunction(this, n"OnVineDetached");

		}
		else
		{
			VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

			AutoAimTargetComp.bIsAutoAimEnabled = false;
			
			VineCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			bIsOpen = true;
		}

		if(bFinishWhenFullyWatered)
		{
			WaterHoseComp.OnFullyWatered.AddUFunction(this, n"OnFullyWatered");
		}

		WaterHoseComp.OnWateringBegin.AddUFunction(this, n"WateringBegun");
		WaterHoseComp.OnWateringEnd.AddUFunction(this, n"WateringStopped");


		if(!bUseDummyWaterIcon || bIsDoubleInteractFlower)
			DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		if(!bUseDummyVineIcon)
			DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	UFUNCTION()
	void WateringBegun()
	{
		bIsDrinking = true;
		OnWateringStarted.Broadcast();
	}

	UFUNCTION()
	void WateringStopped()
	{
		bIsDrinking = false;
		OnWateringStopped.Broadcast();
	}

	UFUNCTION()
	void OnVineAttached()
	{
		bIsAttached = true;

		if(bIsLogSectionVariant)
		{
			if(bIsMayInRangeOfLogVariant)
				WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
			else
				WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
		else
			WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		
		if(bUseDummyWaterIcon)
			DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
		if(bUseDummyVineIcon)
			DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	UFUNCTION()
	void OnVineDetached()
	{
		bIsAttached = false;
		WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(bUseDummyWaterIcon)
			DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		if(bUseDummyVineIcon && !bIsFinished)
			DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WaterAmount = WaterHoseComp.CurrentWaterLevel;
		if(WaterAmount != 0 || WaterHoseComp.DecaySpeed > 0 || WaterHoseComp.DecayAccelerationSpeed > 0)
		{
			if(WaterHoseComp.CurrentDecaySpeed > 0)
				bIsDecaying = true;
			else
				bIsDecaying = false;
		}

		//Test to allow lookat of players via ABP.
/* 
		if(bUseLookAtCodyPosition && bIsAttached)
		{
			PlayerPosition = Game::Cody.ActorLocation;
		}
		else if(bUseLookAtCodyPosition && !bIsAttached)
		{
			PlayerPosition = FVector::ZeroVector;
		} */
	}

	UFUNCTION()
	void OnFullyWatered()
	{
		VineImpactComp.OnVineConnected.UnbindObject(this);
		VineImpactComp.OnVineDisconnected.UnbindObject(this);
		WaterHoseComp.OnFullyWatered.UnbindObject(this);

		WaterHoseComp.OnWateringBegin.UnbindObject(this);
		WaterHoseComp.OnWateringEnd.UnbindObject(this);

		WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(bDisableCollisionOnWatered)
		{
			WaterCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			VineCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		if(bUseDummyWaterIcon)
			DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		if(bUseDummyWaterIcon)
			DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		bIsDecaying = false;
		bIsDrinking = false;
		bIsAttached = false;
		bIsOpen = false;

		WaterAmount = 1.0f;

		HazeAkComp.HazePostEvent(StopIdleEvent);
		
		bIsFinished = true;
		OnWateringPlantFinished.Broadcast();
	}

	UFUNCTION()
	void SetCompleted(bool ShouldBroadcastFinished)
	{
		if(ShouldBroadcastFinished)
			OnFullyWatered();
		else
		{
			VineImpactComp.OnVineConnected.UnbindObject(this);
			VineImpactComp.OnVineDisconnected.UnbindObject(this);
			WaterHoseComp.OnFullyWatered.UnbindObject(this);

			WaterHoseComp.OnWateringBegin.UnbindObject(this);
			WaterHoseComp.OnWateringEnd.UnbindObject(this);

			WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

			bIsDecaying = false;
			bIsDrinking = false;
			bIsAttached = false;
			bIsOpen = false;

			WaterAmount = 1.0f;
			
			bIsFinished = true;
		}
	}

	UFUNCTION()
	void DisableDummyInteracts()
	{
		DummyVineComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		DummyWaterComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}
}
