import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.Glider.FlyingMachineGliderComponent;
import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StartFlyingMachineAdvanced(AHazePlayerCharacter Pilot, AHazePlayerCharacter Gunner, AFlyingMachine Machine, UHazeCapabilitySheet PilotSheet, UHazeCapabilitySheet GunnerSheet)
{
	Machine.EnableActor(nullptr);
	{
		auto PilotComponent = UFlyingMachinePilotComponent::GetOrCreate(Pilot);
		PilotComponent.CurrentMachine = Machine;

		Pilot.AddCapabilitySheet(PilotSheet);
		PilotComponent.Sheet = PilotSheet;
	}

	{
		auto GunnerComponent = UFlyingMachineGunnerComponent::GetOrCreate(Gunner);
		GunnerComponent.CurrentTurret = Machine.AttachedTurret;

		Gunner.AddCapabilitySheet(GunnerSheet);
		GunnerComponent.Sheet = GunnerSheet;
	}

	FFlyingMachineSettings Settings;
	Machine.Health = Settings.MaxHealth;
}

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StopFlyingMachinePilot(AHazePlayerCharacter Pilot)
{
	auto PilotComp = UFlyingMachinePilotComponent::GetOrCreate(Pilot);

	if (ensure(PilotComp != nullptr))
	{
		if (PilotComp.CurrentMachine != nullptr)
		{
			PilotComp.CurrentMachine.DisableActor(nullptr);
			PilotComp.CurrentMachine.Pilot = nullptr;

			Pilot.RemoveCapabilitySheet(PilotComp.Sheet);
			PilotComp.CurrentMachine = nullptr;
			PilotComp.Sheet = nullptr;
		}
	}
}

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StopFlyingMachineGunner(AHazePlayerCharacter Gunner)
{
	auto GunnerComp = UFlyingMachineGunnerComponent::GetOrCreate(Gunner);

	if (ensure(GunnerComp != nullptr))
	{
		if (GunnerComp.CurrentTurret != nullptr)
		{
			Gunner.RemoveCapabilitySheet(GunnerComp.Sheet);
			GunnerComp.CurrentTurret = nullptr;
			GunnerComp.Sheet = nullptr;
		}
	}
}

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StopFlyingMachine(AHazePlayerCharacter Pilot, AHazePlayerCharacter Gunner)
{
	StopFlyingMachinePilot(Pilot);
	StopFlyingMachineGunner(Gunner);
}

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StartFlyingMachineGliderAdvanced(AHazePlayerCharacter LeftPlayer, AHazePlayerCharacter RightPlayer, AFlyingMachineGlider Glider, UHazeCapabilitySheet GliderUserSheet)
{
	UFlyingMachineGliderComponent GliderComp = Glider.GliderComp;
	Glider.EnableActor(nullptr);
	{
		UFlyingMachineGliderUserComponent User = UFlyingMachineGliderUserComponent::GetOrCreate(LeftPlayer);
		GliderComp.LeftUser = User;

		User.Glider = GliderComp;
		User.Spline = Glider.LeftSpline;
		User.Position = 0.5f;

		LeftPlayer.AddCapabilitySheet(GliderUserSheet);
	}
	{
		UFlyingMachineGliderUserComponent User = UFlyingMachineGliderUserComponent::GetOrCreate(RightPlayer);
		GliderComp.RightUser = User;

		User.Glider = GliderComp;
		User.Spline = Glider.RightSpline;
		User.Position = 0.5f;

		RightPlayer.AddCapabilitySheet(GliderUserSheet);
	}
}

UFUNCTION(BlueprintCallable, Category = "Vehicles|FlyingMachine")
void StopFlyingMachineGlider(AFlyingMachineGlider Glider)
{
	Glider.BlockCapabilities(FlyingMachineTag::Glider, Glider);
}