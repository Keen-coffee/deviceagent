using Microsoft.AspNetCore.Mvc;
using System;
using System.Runtime.InteropServices;

namespace Fourteen10.DeviceAgent.Controllers
{
    [ApiController]
    [Route("")]
    public class DeviceInfoController : ControllerBase
    {
        [HttpGet("deviceinfo")]
        public IActionResult GetDeviceInfo()
        {
            try
            {
                var deviceInfo = new
                {
                    computerName = Environment.MachineName,
                    osVersion = Environment.OSVersion.ToString(),
                    processorCount = Environment.ProcessorCount,
                    systemDirectory = Environment.SystemDirectory,
                    timestamp = DateTime.UtcNow,
                    isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows),
                    osDescription = RuntimeInformation.OSDescription,
                    runtimeIdentifier = RuntimeInformation.RuntimeIdentifier,
                    frameWorkDescription = RuntimeInformation.FrameworkDescription,
                    totalMemory = GC.GetTotalMemory(false),
                };

                return Ok(deviceInfo);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        [HttpGet("health")]
        public IActionResult Health()
        {
            return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
        }
    }
}
