import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifier;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifierImpactComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifierShootCapability;

class UMiniatureAmplifierDebugCapability : UHazeDebugCapability
{
	private UConeDetectionComponent ConeDetection;
	private AMiniatureAmplifier MiniatureAmplifier;

	private bool bDrawDebug = false;
	private bool bCapabilityAdded = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MiniatureAmplifier = Cast<AMiniatureAmplifier>(Owner);
		ConeDetection = UConeDetectionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler TogleDrawDebugHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebug", "Toggle Draw Debug");
		TogleDrawDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"MiniatureAmplifier");

		FHazeDebugFunctionCallHandler TogleShootDebugHandler = DebugValues.AddFunctionCall(n"ToggleShootDebug", "Toggle Cody Can Shoot (RT)");
		TogleShootDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"MiniatureAmplifier");
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

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawDebug)
			DrawDebug();
	}

	private void DrawDebug()
	{
		const float Length = ConeDetection.Range;
		const FVector StartLocation = ConeDetection.StartLocation;

		const FVector LocalRightStartLocation = ConeDetection.GetRightStartLocation();
		const FVector LocalLeftStartLocation = ConeDetection.GetLeftStartLocation();
		const FVector LocalUpStartLocation = ConeDetection.GetUpStartLocation();
		const FVector LocalBottomStartLocation = ConeDetection.GetBottomStartLocation();

		const FVector LocalRightOffset = ConeDetection.GetRightOffset();
		const FVector LocalLeftOffset = ConeDetection.GetLeftOffset();
		const FVector LocalUpOffset = ConeDetection.GetUpOffset();
		const FVector LocalBottomOffset = ConeDetection.GetBottomOffset();

		const float ArrowSize = 10.0f;
		const float Thickness = 10;

		System::DrawDebugArrow(LocalRightStartLocation, LocalRightStartLocation + (LocalRightOffset * Length), ArrowSize, FLinearColor::Green, 0, Thickness);
		System::DrawDebugArrow(LocalLeftStartLocation, LocalLeftStartLocation + (LocalLeftOffset * Length), ArrowSize, FLinearColor::Green, 0, Thickness);

		System::DrawDebugArrow(LocalUpStartLocation, LocalUpStartLocation + (LocalUpOffset * Length), ArrowSize, FLinearColor::Blue, 0, Thickness);
		System::DrawDebugArrow(LocalBottomStartLocation, LocalBottomStartLocation + (LocalBottomOffset * Length), ArrowSize, FLinearColor::Blue, 0, Thickness);
	
		const float NormalLocationLength = Length * 0.5f;
		const float NormalLength = 30.0f;

		const FVector RightNormalStartLocation = LocalRightStartLocation + (LocalRightOffset * NormalLocationLength);
		const FVector LeftNormalStartLocation = LocalLeftStartLocation + (LocalLeftOffset * NormalLocationLength);
		const FVector UpNormalStartLocation = LocalUpStartLocation + (LocalUpOffset * NormalLocationLength);
		const FVector BottomNormalStartLocation = LocalBottomStartLocation + (LocalBottomOffset * NormalLocationLength);

		const float NormalLineThickness = 5;

		System::DrawDebugArrow(RightNormalStartLocation, RightNormalStartLocation + (ConeDetection.GetRightNormal() * NormalLength), ArrowSize, FLinearColor::Red, 0, NormalLineThickness);
		System::DrawDebugArrow(LeftNormalStartLocation, LeftNormalStartLocation - (ConeDetection.GetLeftNormal() * NormalLength), ArrowSize, FLinearColor::Red, 0, NormalLineThickness);
		System::DrawDebugArrow(UpNormalStartLocation, UpNormalStartLocation + (ConeDetection.GetUpNormal() * NormalLength), ArrowSize, FLinearColor::Red, 0, NormalLineThickness);
		System::DrawDebugArrow(BottomNormalStartLocation, BottomNormalStartLocation - (ConeDetection.GetBottomNormal() * NormalLength), ArrowSize, FLinearColor::Red, 0, NormalLineThickness);

		System::DrawDebugArrow(ConeDetection.GetStartLocation(), ConeDetection.GetStartLocation() + (ConeDetection.GetForward() * Length), ArrowSize, FLinearColor::LucBlue, 0, NormalLineThickness);

		TArray<FAmplifierImpactNetInfo> Hits;
		MiniatureAmplifier.GatherImpacts(Hits);

		for(FAmplifierImpactNetInfo HitInfo : Hits)
		{
			System::DrawDebugSphere(HitInfo.ImpactPoint, 100.0f, 12, FLinearColor::Green);
		}
	}

	UFUNCTION()
	private void ToggleDrawDebug()
	{
		bDrawDebug = !bDrawDebug;
	}

	UFUNCTION()
	private void ToggleShootDebug()
	{
		AHazePlayerCharacter Player = Game::GetCody();
		
		if(!bCapabilityAdded)
		{
			Player.AddCapability(UMiniatureAmplifierShootCapability::StaticClass());
			bCapabilityAdded = true;
		}
		else
		{
			bCapabilityAdded = false;
			Player.RemoveCapability(UMiniatureAmplifierShootCapability::StaticClass());
		}
	}
}
