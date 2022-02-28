import Rice.TemporalLog.TemporalLogComponent;

class UCameraTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		UHazeActiveCameraUserComponent Comp = UHazeActiveCameraUserComponent::Get(Actor);
		if (Comp == nullptr)
			return;

		UHazeCameraViewPoint ViewPoint = Comp.GetCameraViewPoint();

		FVector ViewLocation = ViewPoint.ViewLocation;
		FRotator ViewRotation = ViewPoint.ViewRotation;
		float FOV = ViewPoint.ViewFOV;

		auto ComponentLog = Log.LogObject(n"Components", Comp, bLogProperties = false);
		ComponentLog.LogCamera(n"CameraPosition", ViewLocation, ViewRotation, FOV, FLinearColor::Red, Thickness = 5.f, bDrawByDefault = true);
		ComponentLog.LogValue(n"CameraRotation", ViewRotation.ToString());
		ComponentLog.LogValue(n"FOV", FOV);
		ComponentLog.LogValue(n"DesiredRotation", Comp.DesiredRotation.ToString());
		ComponentLog.LogValue(n"Camera", ViewPoint.CurrentCamera.Name + " ("+ViewPoint.CurrentCamera.Owner.Name+")");
	}
};